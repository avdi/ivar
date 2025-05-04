# frozen_string_literal: true

require_relative "test_helper"

class TestIvarWithInitialValues < Minitest::Test
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

  def test_ivar_with_initial_values
    # Create a class with the ivar macro and initial values
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with initial values
      ivar ":@foo": 123, ":@bar": 456

      def initialize
        # The values should already be set before this method is called
        @foo += 1
        @bar += 1
      end

      def values
        [@foo, @bar]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the instance variables were initialized with the specified values
    # and then modified by the initialize method
    assert_equal [124, 457], instance.values
  end

  def test_ivar_with_initial_values_and_regular_declarations
    # Create a class with both types of declarations
    klass = Class.new do
      include Ivar::Checked

      # Declare some variables with initial values and some without
      ivar :@regular_var
      ivar ":@initialized_var": "initial value"

      def initialize
        # We don't set @regular_var here
        # But @initialized_var should already be set
        @initialized_var = @initialized_var.upcase
      end

      def values
        [
          defined?(@regular_var) ? @regular_var : "undefined",
          @initialized_var
        ]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the regular variable is undefined
    # and the initialized variable has the expected value
    values = instance.values
    assert_equal "undefined", values[0], "@regular_var should be undefined"
    assert_equal "INITIAL VALUE", values[1], "@initialized_var should be 'INITIAL VALUE'"
  end

  def test_ivar_with_initial_values_inheritance
    # Create a parent class with initial values
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with initial values in parent
      ivar ":@parent_var": "parent value"

      def initialize
        # The value should already be set
        @parent_var = @parent_var.upcase
      end
    end

    # Create a child class that inherits and adds its own initial values
    child_klass = Class.new(parent_klass) do
      # Declare instance variables with initial values in child
      ivar ":@child_var": "child value"

      def initialize
        # Call parent initialize first
        super
        # Then modify the child var
        @child_var = @child_var.upcase
      end

      def values
        [@parent_var, @child_var]
      end
    end

    # Create an instance of the child class
    instance = child_klass.new

    # Check that both parent and child variables were initialized
    # and then modified by their respective initialize methods
    values = instance.values
    assert_equal "PARENT VALUE", values[0], "@parent_var should be 'PARENT VALUE'"
    assert_equal "CHILD VALUE", values[1], "@child_var should be 'CHILD VALUE'"
  end

  def test_ivar_with_complex_initial_values
    # Create a class with complex initial values (arrays, hashes, etc.)
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with complex initial values
      ivar ":@array": [1, 2, 3],
        ":@hash": {a: 1, b: 2},
        ":@nested": {list: [4, 5, 6], data: {c: 3}}

      def initialize
        # Modify the complex values
        @array << 4
        @hash[:c] = 3
        @nested[:list] << 7
      end

      def values
        [@array, @hash, @nested]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the complex values were properly initialized and modified
    values = instance.values
    assert_equal [1, 2, 3, 4], values[0], "@array should be [1, 2, 3, 4]"
    assert_equal({a: 1, b: 2, c: 3}, values[1], "@hash should include the new key")
    assert_equal({list: [4, 5, 6, 7], data: {c: 3}}, values[2], "@nested should be properly modified")
  end

  def test_ivar_initial_values_override_in_subclass
    # Create a parent class with initial values
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with initial values
      ivar ":@shared_var": "parent value"

      def initialize
        # No modifications here
      end
    end

    # Create a child class that overrides the initial value
    child_klass = Class.new(parent_klass) do
      # Override the initial value from the parent
      ivar ":@shared_var": "child value"

      def initialize
        super
      end

      def value
        @shared_var
      end
    end

    # Create instances of both classes
    parent_instance = parent_klass.new
    child_instance = child_klass.new

    # Check that the parent instance has the parent value
    assert_equal "parent value", parent_instance.instance_variable_get(:@shared_var)

    # Check that the child instance has the child value
    assert_equal "child value", child_instance.value
  end
end
