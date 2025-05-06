# frozen_string_literal: true

require_relative "test_helper"

class TestIvarWithPositionalInit < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_ivar_with_positional_init
    # Create a class with the ivar macro and init: :positional
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization
      ivar :@foo, init: :positional

      # Track what positional args are received by initialize
      attr_reader :received_args

      def initialize(bar = nil)
        # The foo arg should be "peeled off" and not passed to this method
        # but bar should be passed through if provided
        @received_args = {
          foo: binding.local_variable_defined?(:foo) ? :received : :not_received,
          bar: bar
        }
      end

      def foo_value
        @foo
      end
    end

    # Create an instance with both positional arguments
    instance = klass.new("from arg", "passed through")

    # Check that the instance variable was initialized from the positional argument
    assert_equal "from arg", instance.foo_value

    # Check that foo was peeled off and not passed to initialize
    assert_equal :not_received, instance.received_args[:foo]

    # Check that bar was passed through to initialize
    assert_equal "passed through", instance.received_args[:bar]
  end

  def test_ivar_with_arg_init
    # Create a class with the ivar macro and init: :arg (alias for :positional)
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with arg initialization
      ivar :@bar, init: :arg

      def initialize
        # The value should be set from the positional argument
        # before this method is called
      end

      def bar_value
        @bar
      end
    end

    # Create an instance with the positional argument
    instance = klass.new("from arg")

    # Check that the instance variable was initialized from the positional argument
    assert_equal "from arg", instance.bar_value
  end

  def test_ivar_with_positional_init_default_value
    # Create a class with the ivar macro and init: :positional
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization and a value
      ivar :@foo, init: :positional, value: "default value"

      def initialize
        # If the positional argument is not provided, it should use the value from ivar
      end

      def foo_value
        @foo
      end
    end

    # Create an instance without the positional argument
    instance = klass.new

    # Check that the instance variable was initialized with the default value from ivar
    assert_equal "default value", instance.foo_value
  end

  def test_ivar_with_positional_init_and_value
    # Create a class with the ivar macro, init: :positional, and a value
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization and a default value
      ivar :@foo, init: :positional, value: "initial value"

      def initialize
        # The value should be set from the positional argument if provided,
        # otherwise it should use the initial value
      end

      def foo_value
        @foo
      end
    end

    # Create an instance with the positional argument
    instance_with_arg = klass.new("from arg")
    assert_equal "from arg", instance_with_arg.foo_value

    # Create an instance without the positional argument
    instance_without_arg = klass.new
    assert_equal "initial value", instance_without_arg.foo_value
  end

  def test_ivar_with_multiple_positional_init
    # Create a class with multiple ivars using positional initialization
    klass = Class.new do
      include Ivar::Checked

      # Declare multiple instance variables with positional initialization
      ivar :@foo, :@bar, :@baz, init: :positional

      def initialize
        # All values should be set from positional arguments
      end

      def values
        [@foo, @bar, @baz]
      end
    end

    # Create an instance with all positional arguments
    instance = klass.new("foo value", "bar value", "baz value")

    # Check that all instance variables were initialized from positional arguments
    assert_equal ["foo value", "bar value", "baz value"], instance.values
  end

  def test_ivar_with_positional_init_and_accessor
    # Create a class with positional initialization and accessor
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization and accessor
      ivar :@foo, :@bar, init: :positional, accessor: true

      def initialize
        # Values should be set from positional arguments
      end
    end

    # Create an instance with positional arguments
    instance = klass.new("foo value", "bar value")

    # Check that the accessor methods work correctly
    assert_equal "foo value", instance.foo
    assert_equal "bar value", instance.bar

    # Check that the writer methods work correctly
    instance.foo = "new foo"
    instance.bar = "new bar"

    assert_equal "new foo", instance.foo
    assert_equal "new bar", instance.bar
  end

  def test_positional_args_ordering
    # Create a class with ivars declared in a specific order
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables in a specific order
      ivar :@first, init: :positional
      ivar :@second, init: :positional
      ivar :@third, init: :positional

      def values
        [@first, @second, @third]
      end
    end

    # Create an instance with positional arguments
    instance = klass.new("value 1", "value 2", "value 3")

    # Check that the instance variables were initialized in the declared order
    assert_equal ["value 1", "value 2", "value 3"], instance.values
  end

  def test_warnings_for_undeclared_variables
    # Create a class with positional initialization and an undeclared variable
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization
      ivar :@declared_var, init: :positional

      def initialize
        # Use a declared variable
        @declared_var = @declared_var.to_s.upcase

        # Use an undeclared variable (should trigger a warning)
        @undeclared_var = "this should trigger a warning"
      end

      def use_misspelled_variable
        # Misspelled variable (should trigger a warning)
        @declraed_var = "misspelled"
      end
    end

    # Create an instance and use the misspelled variable
    instance = klass.new("value")

    # Capture stderr output when using misspelled variable
    stderr_output = capture_stderr do
      instance.use_misspelled_variable
    end

    # Check that warnings were generated for undeclared/misspelled variables
    assert_match(/unknown instance variable @undeclared_var/, stderr_output,
      "Should warn about undeclared variable")
    assert_match(/unknown instance variable @declraed_var/, stderr_output,
      "Should warn about misspelled variable")

    # Check that no warnings were generated for declared variables
    refute_match(/unknown instance variable @declared_var/, stderr_output,
      "Should not warn about declared variable")
  end

  def test_no_warnings_for_declared_variables
    # Create a class with positional initialization
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization
      ivar :@foo, :@bar, :@baz, init: :positional

      def initialize
        # Modify the declared variables
        @foo = @foo.to_s.upcase
        @bar = @bar.to_s.upcase
        @baz = @baz.to_s.upcase
      end

      def values
        [@foo, @bar, @baz]
      end
    end

    # Create an instance and access the variables
    instance = klass.new("foo", "bar", "baz")

    # Capture stderr output when accessing variables
    stderr_output = capture_stderr do
      # Access the values to ensure the variables are used
      instance.values
    end

    # Check that no warnings were generated for declared variables
    refute_match(/unknown instance variable @foo/, stderr_output,
      "Should not warn about declared variable @foo")
    refute_match(/unknown instance variable @bar/, stderr_output,
      "Should not warn about declared variable @bar")
    refute_match(/unknown instance variable @baz/, stderr_output,
      "Should not warn about declared variable @baz")
  end
end
