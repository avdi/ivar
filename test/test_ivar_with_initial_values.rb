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
      ivar "@foo": 123, "@bar": 456

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
      ivar "@initialized_var": "initial value"

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

      def instance_vars
        instance_variables
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the regular variable is undefined
    # and the initialized variable has the expected value
    values = instance.values
    assert_equal "undefined", values[0], "@regular_var should be undefined"
    assert_equal "INITIAL VALUE", values[1], "@initialized_var should be 'INITIAL VALUE'"

    # Check that only the initialized variable appears in instance_variables
    instance_vars = instance.instance_vars
    refute_includes instance_vars, :@regular_var, "@regular_var should not be in instance_variables"
    assert_includes instance_vars, :@initialized_var, "@initialized_var should be in instance_variables"
  end

  def test_ivar_with_initial_values_inheritance
    # Create a parent class with initial values
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with initial values in parent
      ivar "@parent_var": "parent value"

      def initialize
        # The value should already be set
        @parent_var = @parent_var.upcase
      end
    end

    # Create a child class that inherits and adds its own initial values
    child_klass = Class.new(parent_klass) do
      # Declare instance variables with initial values in child
      ivar "@child_var": "child value"

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
      ivar "@array": [1, 2, 3],
        "@hash": {a: 1, b: 2},
        "@nested": {list: [4, 5, 6], data: {c: 3}}

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
      ivar "@shared_var": "parent value"

      def initialize
        # No modifications here
      end
    end

    # Create a child class that overrides the initial value
    child_klass = Class.new(parent_klass) do
      # Override the initial value from the parent
      ivar "@shared_var": "child value"

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

  def test_ivar_with_explicit_nil_value
    # Create a class with an ivar explicitly set to nil
    klass = Class.new do
      include Ivar::Checked

      # Declare an instance variable with nil as the initial value
      ivar "@nil_var": nil
      # Declare a regular variable without an initial value
      ivar :@undefined_var

      def initialize
        # No modifications here
      end

      def check_vars
        {
          nil_var_defined: defined?(@nil_var),
          nil_var_value: @nil_var,
          undefined_var_defined: defined?(@undefined_var)
        }
      end

      def instance_vars
        instance_variables
      end
    end

    # Create an instance
    instance = klass.new

    # Check the variables
    result = instance.check_vars

    # @nil_var should be defined and have a nil value
    assert_equal "instance-variable", result[:nil_var_defined], "@nil_var should be defined"
    assert_nil result[:nil_var_value], "@nil_var should be nil"

    # @undefined_var should be undefined
    assert_nil result[:undefined_var_defined], "@undefined_var should be undefined"

    # Check instance_variables list
    instance_vars = instance.instance_vars
    assert_includes instance_vars, :@nil_var, "@nil_var should be in instance_variables"
    refute_includes instance_vars, :@undefined_var, "@undefined_var should not be in instance_variables"
  end

  def test_ivar_with_shared_value
    # Create a class with multiple ivars sharing the same initial value
    klass = Class.new do
      include Ivar::Checked

      # Declare multiple instance variables with the same initial value
      ivar :@foo, :@bar, value: 123

      # Also declare a variable with a different value
      ivar "@baz": 456

      def initialize
        # Modify one of the variables
        @foo += 1
      end

      def values
        [@foo, @bar, @baz]
      end

      def instance_vars
        instance_variables
      end
    end

    # Create an instance
    instance = klass.new

    # Check that both variables were initialized with the same value
    # and @foo was modified by the initializer
    values = instance.values
    assert_equal 124, values[0], "@foo should be 124 (123 + 1)"
    assert_equal 123, values[1], "@bar should be 123"
    assert_equal 456, values[2], "@baz should be 456"

    # Check that all variables are in the instance_variables list
    instance_vars = instance.instance_vars
    assert_includes instance_vars, :@foo, "@foo should be in instance_variables"
    assert_includes instance_vars, :@bar, "@bar should be in instance_variables"
    assert_includes instance_vars, :@baz, "@baz should be in instance_variables"
  end

  def test_ivar_with_shared_value_and_override
    # Create a class with shared values and an override
    klass = Class.new do
      include Ivar::Checked

      # Declare multiple instance variables with the same initial value
      ivar :@a, :@b, :@c, value: "shared"

      # Override one of the variables with a different value
      ivar "@b": "override"

      def initialize
        # No modifications
      end

      def values
        [@a, @b, @c]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that @a and @c have the shared value, but @b has the override
    values = instance.values
    assert_equal "shared", values[0], "@a should have the shared value"
    assert_equal "override", values[1], "@b should have the override value"
    assert_equal "shared", values[2], "@c should have the shared value"
  end

  def test_ivar_with_shared_false_value
    # Create a class with multiple ivars sharing a false value
    # This tests the special handling for false values
    klass = Class.new do
      include Ivar::Checked

      # Declare multiple instance variables with false as the initial value
      ivar :@flag1, :@flag2, value: false

      def initialize
        # No modifications
      end

      def values
        {
          flag1: @flag1,
          flag2: @flag2,
          flag1_defined: defined?(@flag1),
          flag2_defined: defined?(@flag2)
        }
      end
    end

    # Create an instance
    instance = klass.new

    # Check that both variables were initialized with false
    values = instance.values
    assert_equal false, values[:flag1], "@flag1 should be false"
    assert_equal false, values[:flag2], "@flag2 should be false"
    assert_equal "instance-variable", values[:flag1_defined], "@flag1 should be defined"
    assert_equal "instance-variable", values[:flag2_defined], "@flag2 should be defined"
  end

  def test_ivar_with_block_for_initial_values
    # Create a class with ivars initialized using a block
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with a block that generates values based on the variable name
      ivar(:@baz, :@buz) { |varname| "#{varname} default" }

      def initialize
        # No modifications
      end

      def values
        [@baz, @buz]
      end

      def instance_vars
        instance_variables
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the variables were initialized with the values generated by the block
    values = instance.values
    assert_equal "@baz default", values[0], "@baz should be '@baz default'"
    assert_equal "@buz default", values[1], "@buz should be '@buz default'"

    # Check that both variables are in the instance_variables list
    instance_vars = instance.instance_vars
    assert_includes instance_vars, :@baz, "@baz should be in instance_variables"
    assert_includes instance_vars, :@buz, "@buz should be in instance_variables"
  end

  def test_ivar_with_block_and_override
    # Create a class with ivars initialized using a block and an override
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with a block that generates values based on the variable name
      ivar(:@var1, :@var2, :@var3) { |varname| "#{varname} default" }

      # Override one of the variables with a different value
      ivar "@var2": "override"

      def initialize
        # Modify one of the variables
        @var3 = @var3.upcase
      end

      def values
        [@var1, @var2, @var3]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that @var1 has the block-generated value, @var2 has the override value,
    # and @var3 has the block-generated value modified by initialize
    values = instance.values
    assert_equal "@var1 default", values[0], "@var1 should have the block-generated value"
    assert_equal "override", values[1], "@var2 should have the override value"
    assert_equal "@VAR3 DEFAULT", values[2], "@var3 should have the modified block-generated value"
  end
end
