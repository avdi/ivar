# frozen_string_literal: true

require_relative "test_helper"

class TestIvarAttrMethods < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache

    # Capture stderr to prevent warnings from appearing in test output
    @original_stderr = $stderr
    $stderr = StringIO.new
  end

  def teardown
    # Restore stderr
    $stderr = @original_stderr
  end

  def test_ivar_with_reader
    # Create a class with the ivar macro and reader: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with reader
      ivar :@foo, :@bar, reader: true, value: "initial"

      def initialize
        # Modify one of the variables
        @foo = "modified"
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the reader methods were created and work correctly
    assert_equal "modified", instance.foo
    assert_equal "initial", instance.bar
  end

  def test_ivar_with_writer
    # Create a class with the ivar macro and writer: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with writer
      ivar :@foo, :@bar, writer: true, value: "initial"

      def initialize
        # No modifications
      end

      # Add readers for testing
      attr_reader :foo

      attr_reader :bar
    end

    # Create an instance
    instance = klass.new

    # Check that the writer methods were created and work correctly
    instance.foo = "modified foo"
    instance.bar = "modified bar"

    assert_equal "modified foo", instance.foo
    assert_equal "modified bar", instance.bar
  end

  def test_ivar_with_accessor
    # Create a class with the ivar macro and accessor: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with accessor
      ivar :@foo, :@bar, accessor: true, value: "initial"

      def initialize
        # Modify one of the variables
        @foo = "modified in initialize"
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the reader methods were created and work correctly
    assert_equal "modified in initialize", instance.foo
    assert_equal "initial", instance.bar

    # Check that the writer methods were created and work correctly
    instance.foo = "modified by writer"
    instance.bar = "modified by writer"

    assert_equal "modified by writer", instance.foo
    assert_equal "modified by writer", instance.bar
  end

  def test_ivar_with_hash_syntax_and_accessor
    # Create a class with the ivar macro using hash syntax and accessor: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with accessor using hash syntax
      ivar "@foo": "foo value", "@bar": "bar value", accessor: true

      def initialize
        # No modifications
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the reader methods were created and work correctly
    assert_equal "foo value", instance.foo
    assert_equal "bar value", instance.bar

    # Check that the writer methods were created and work correctly
    instance.foo = "new foo"
    instance.bar = "new bar"

    assert_equal "new foo", instance.foo
    assert_equal "new bar", instance.bar
  end

  def test_ivar_with_block_and_reader
    # Create a class with the ivar macro using a block and reader: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with a block and reader
      ivar(:@foo, :@bar, reader: true) { |varname| "#{varname} value" }

      def initialize
        # No modifications
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the reader methods were created and work correctly
    assert_equal "@foo value", instance.foo
    assert_equal "@bar value", instance.bar
  end

  def test_ivar_without_at_symbol
    # Create a class with the ivar macro using symbols without @ and accessor: true
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables without @ symbol
      ivar :foo, :bar, accessor: true, value: "initial"

      def initialize
        # No modifications
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the accessor methods were created and work correctly
    assert_equal "initial", instance.foo
    assert_equal "initial", instance.bar

    instance.foo = "modified"
    instance.bar = "modified"

    assert_equal "modified", instance.foo
    assert_equal "modified", instance.bar

    # Check that the instance variables were created with @ symbol
    assert_includes instance.instance_variables, :@foo
    assert_includes instance.instance_variables, :@bar
  end
end
