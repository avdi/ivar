# frozen_string_literal: true

require_relative "test_helper"

class TestIvarWithKwargInit < Minitest::Test
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

  def test_ivar_with_kwarg_init
    # Create a class with the ivar macro and init: :kwarg
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization
      ivar :@foo, init: :kwarg

      # Track what keywords are received by initialize
      attr_reader :received_kwargs

      def initialize(bar: nil)
        # The foo keyword should be "peeled off" and not passed to this method
        # but bar should be passed through
        @received_kwargs = {
          foo: binding.local_variable_defined?(:foo) ? :received : :not_received,
          bar: binding.local_variable_defined?(:bar) ? bar : :not_received
        }
      end

      def foo_value
        @foo
      end
    end

    # Create an instance with both keywords
    instance = klass.new(foo: "from kwarg", bar: "passed through")

    # Check that the instance variable was initialized from the keyword argument
    assert_equal "from kwarg", instance.foo_value

    # Check that foo was peeled off and not passed to initialize
    assert_equal :not_received, instance.received_kwargs[:foo]

    # Check that bar was passed through to initialize
    assert_equal "passed through", instance.received_kwargs[:bar]
  end

  def test_ivar_with_keyword_init
    # Create a class with the ivar macro and init: :keyword (alias for :kwarg)
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with keyword initialization
      ivar :@bar, init: :keyword

      def initialize
        # The value should be set from the keyword argument
        # before this method is called
      end

      def bar_value
        @bar
      end
    end

    # Create an instance with the keyword argument
    instance = klass.new(bar: "from keyword")

    # Check that the instance variable was initialized from the keyword argument
    assert_equal "from keyword", instance.bar_value
  end

  def test_ivar_with_kwarg_init_default_value
    # Create a class with the ivar macro and init: :kwarg
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization and a value
      ivar :@foo, init: :kwarg, value: "default value"

      def initialize
        # If the keyword argument is not provided, it should use the value from ivar
      end

      def foo_value
        @foo
      end
    end

    # Create an instance without the keyword argument
    instance = klass.new

    # Check that the instance variable was initialized with the default value from ivar
    assert_equal "default value", instance.foo_value
  end

  def test_ivar_with_kwarg_init_and_value
    # Create a class with the ivar macro, init: :kwarg, and a value
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization and a default value
      ivar :@foo, init: :kwarg, value: "initial value"

      def initialize
        # The value should be set from the keyword argument if provided,
        # otherwise it should use the initial value
      end

      def foo_value
        @foo
      end
    end

    # Create an instance with the keyword argument
    instance_with_kwarg = klass.new(foo: "from kwarg")
    assert_equal "from kwarg", instance_with_kwarg.foo_value

    # Create an instance without the keyword argument
    instance_without_kwarg = klass.new
    assert_equal "initial value", instance_without_kwarg.foo_value
  end

  def test_ivar_with_kwarg_init_inheritance
    # Create a parent class with kwarg initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization
      ivar :@parent_var, init: :kwarg

      def initialize
        # The value should be set from the keyword argument
      end

      def parent_var_value
        @parent_var
      end
    end

    # Create a child class that inherits and adds its own kwarg initialization
    child_klass = Class.new(parent_klass) do
      # Declare instance variables with kwarg initialization
      ivar :@child_var, init: :kwarg

      def initialize
        # Call parent initialize first
        super
      end

      def child_var_value
        @child_var
      end
    end

    # Create an instance with both keyword arguments
    instance = child_klass.new(parent_var: "parent value", child_var: "child value")

    # Check that both instance variables were initialized from keyword arguments
    assert_equal "parent value", instance.parent_var_value
    assert_equal "child value", instance.child_var_value
  end

  def test_ivar_with_multiple_kwarg_init
    # Create a class with multiple ivars using kwarg initialization
    klass = Class.new do
      include Ivar::Checked

      # Declare multiple instance variables with kwarg initialization
      ivar :@foo, :@bar, :@baz, init: :kwarg

      def initialize
        # All values should be set from keyword arguments
      end

      def values
        [@foo, @bar, @baz]
      end
    end

    # Create an instance with all keyword arguments
    instance = klass.new(foo: "foo value", bar: "bar value", baz: "baz value")

    # Check that all instance variables were initialized from keyword arguments
    assert_equal ["foo value", "bar value", "baz value"], instance.values
  end

  def test_ivar_with_kwarg_init_and_accessor
    # Create a class with kwarg initialization and accessor
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization and accessor
      ivar :@foo, :@bar, init: :kwarg, accessor: true

      def initialize
        # Values should be set from keyword arguments
      end
    end

    # Create an instance with keyword arguments
    instance = klass.new(foo: "foo value", bar: "bar value")

    # Check that the accessor methods work correctly
    assert_equal "foo value", instance.foo
    assert_equal "bar value", instance.bar

    # Check that the writer methods work correctly
    instance.foo = "new foo"
    instance.bar = "new bar"

    assert_equal "new foo", instance.foo
    assert_equal "new bar", instance.bar
  end
end
