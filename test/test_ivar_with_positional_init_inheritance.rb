# frozen_string_literal: true

require_relative "test_helper"

class TestIvarWithPositionalInitInheritance < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_ivar_with_positional_init_inheritance
    # Create a parent class with positional initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization
      ivar :@parent_var, init: :positional

      def initialize
        # The value should be set from the positional argument
      end

      def parent_var_value
        @parent_var
      end
    end

    # Create a child class that inherits and adds its own positional initialization
    child_klass = Class.new(parent_klass) do
      # Declare instance variables with positional initialization
      ivar :@child_var, init: :positional

      def initialize
        # Call parent initialize first
        super
      end

      def child_var_value
        @child_var
      end
    end

    # Create an instance with both positional arguments
    # Parent vars should be assigned first, then child vars
    instance = child_klass.new("parent value", "child value")

    # Check that both instance variables were initialized from positional arguments
    assert_equal "parent value", instance.parent_var_value
    assert_equal "child value", instance.child_var_value
  end

  def test_ivar_with_positional_init_inheritance_defaults_and_overrides
    # Create a parent class with positional initialization and defaults
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization and defaults
      ivar :@parent_var1, init: :positional, value: "parent default 1"
      ivar :@parent_var2, init: :positional, value: "parent default 2"

      def initialize(extra_arg = nil)
        @extra_parent = extra_arg
      end

      def values
        {
          parent_var1: @parent_var1,
          parent_var2: @parent_var2,
          extra_parent: @extra_parent
        }
      end
    end

    # Create a child class that inherits and adds its own positional initialization
    child_klass = Class.new(parent_klass) do
      # Declare child-specific instance variables with positional initialization
      ivar :@child_var1, init: :positional, value: "child default 1"
      ivar :@child_var2, init: :positional, value: "child default 2"

      def initialize(parent_extra = nil, child_extra = nil)
        super(parent_extra)
        @child_extra = child_extra
      end

      def all_values
        parent_values = values
        parent_values.merge({
          child_var1: @child_var1,
          child_var2: @child_var2,
          child_extra: @child_extra
        })
      end
    end

    # Test 1: Create instance with defaults only (no args)
    instance1 = child_klass.new
    expected1 = {
      parent_var1: "parent default 1",
      parent_var2: "parent default 2",
      extra_parent: nil,
      child_var1: "child default 1",
      child_var2: "child default 2",
      child_extra: nil
    }
    assert_equal expected1, instance1.all_values

    # Test 2: Override parent variables
    instance2 = child_klass.new(
      "custom parent 1",
      "custom parent 2"
    )
    expected2 = {
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2",
      extra_parent: nil,
      child_var1: "child default 1",
      child_var2: "child default 2",
      child_extra: nil
    }
    assert_equal expected2, instance2.all_values

    # Test 3: Override child variables
    instance3 = child_klass.new(
      "parent default 1", # Use default for parent_var1
      "parent default 2", # Use default for parent_var2
      "custom child 1",
      "custom child 2"
    )
    expected3 = {
      parent_var1: "parent default 1",
      parent_var2: "parent default 2",
      extra_parent: nil,
      child_var1: "custom child 1",
      child_var2: "custom child 2",
      child_extra: nil
    }
    assert_equal expected3, instance3.all_values

    # Test 4: Override everything and pass through extra args
    instance5 = child_klass.new(
      "custom parent 1",
      "custom parent 2",
      "custom child 1",
      "custom child 2",
      "parent extra", # extra_arg
      "child extra" # child_extra
    )
    expected5 = {
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2",
      child_var1: "custom child 1",
      child_var2: "custom child 2",
      extra_parent: "parent extra",
      child_extra: "child extra"
    }
    assert_equal expected5, instance5.all_values
  end

  def test_deep_inheritance_chain_with_positional_init
    # Create a base class with positional initialization
    base_klass = Class.new do
      include Ivar::Checked

      # Declare base instance variables with positional initialization
      ivar :@base_var1, init: :positional
      ivar :@base_var2, init: :positional

      def initialize
        # Values should be set from positional arguments
      end

      def base_values
        [@base_var1, @base_var2]
      end
    end

    # Create a middle class that inherits and adds its own positional initialization
    middle_klass = Class.new(base_klass) do
      # Declare middle instance variables with positional initialization
      ivar :@middle_var1, init: :positional
      ivar :@middle_var2, init: :positional

      def initialize
        super
      end

      def middle_values
        [@middle_var1, @middle_var2]
      end
    end

    # Create a leaf class that inherits and adds its own positional initialization
    leaf_klass = Class.new(middle_klass) do
      # Declare leaf instance variables with positional initialization
      ivar :@leaf_var1, init: :positional
      ivar :@leaf_var2, init: :positional

      def initialize
        super
      end

      def leaf_values
        [@leaf_var1, @leaf_var2]
      end

      def all_values
        base_values + middle_values + leaf_values
      end
    end

    # Create an instance with all positional arguments
    # The order should be: base vars, middle vars, leaf vars
    instance = leaf_klass.new(
      "base1", "base2",     # Base class vars
      "middle1", "middle2", # Middle class vars
      "leaf1", "leaf2"      # Leaf class vars
    )

    # Check that all instance variables were initialized in the correct order
    expected = [
      "base1", "base2",     # Base class vars
      "middle1", "middle2", # Middle class vars
      "leaf1", "leaf2"      # Leaf class vars
    ]
    assert_equal expected, instance.all_values
  end

  def test_mixed_positional_and_kwarg_init
    # Create a parent class with mixed initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with different initialization methods
      ivar :@parent_pos1, init: :positional
      ivar :@parent_pos2, init: :positional
      ivar :@parent_kw1, init: :kwarg
      ivar :@parent_kw2, init: :kwarg

      def initialize
        # Values should be set from arguments
      end

      def parent_values
        {
          parent_pos1: @parent_pos1,
          parent_pos2: @parent_pos2,
          parent_kw1: @parent_kw1,
          parent_kw2: @parent_kw2
        }
      end
    end

    # Create a child class with mixed initialization
    child_klass = Class.new(parent_klass) do
      # Declare instance variables with different initialization methods
      ivar :@child_pos1, init: :positional
      ivar :@child_pos2, init: :positional
      ivar :@child_kw1, init: :kwarg
      ivar :@child_kw2, init: :kwarg

      def initialize
        super
      end

      def child_values
        {
          child_pos1: @child_pos1,
          child_pos2: @child_pos2,
          child_kw1: @child_kw1,
          child_kw2: @child_kw2
        }
      end

      def all_values
        parent_values.merge(child_values)
      end
    end

    # Create an instance with both positional and keyword arguments
    instance = child_klass.new(
      "parent pos1", "parent pos2", "child pos1", "child pos2",
      parent_kw1: "parent kw1", parent_kw2: "parent kw2",
      child_kw1: "child kw1", child_kw2: "child kw2"
    )

    # Check that all instance variables were initialized correctly
    expected = {
      parent_pos1: "parent pos1",
      parent_pos2: "parent pos2",
      parent_kw1: "parent kw1",
      parent_kw2: "parent kw2",
      child_pos1: "child pos1",
      child_pos2: "child pos2",
      child_kw1: "child kw1",
      child_kw2: "child kw2"
    }
    assert_equal expected, instance.all_values
  end

  def test_warnings_for_undeclared_variables_in_inheritance
    # Create a parent class with positional initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare parent instance variables with positional initialization
      ivar :@parent_declared, init: :positional

      def initialize
        # Use the declared variable
        @parent_declared = @parent_declared.to_s.upcase
      end

      def use_undeclared_parent_var
        # Use an undeclared variable (should trigger a warning)
        @parent_undeclared = "this should trigger a warning"
      end
    end

    # Create a child class that inherits
    child_klass = Class.new(parent_klass) do
      # Declare child instance variables with positional initialization
      ivar :@child_declared, init: :positional

      def initialize
        super
        # Use the declared variable
        @child_declared = @child_declared.to_s.upcase
      end

      def use_undeclared_child_var
        # Use an undeclared variable (should trigger a warning)
        @child_undeclared = "this should trigger a warning"
      end

      def use_misspelled_parent_var
        # Misspelled parent variable (should trigger a warning)
        @parent_declraed = "misspelled"
      end

      def use_misspelled_child_var
        # Misspelled child variable (should trigger a warning)
        @child_declraed = "misspelled"
      end

      def use_parent_var
        # Use parent's declared variable (should NOT trigger a warning)
        @parent_declared = "using parent var"
      end
    end

    # Capture stderr output when using variables
    stderr_output = capture_stderr do
      # Create an instance and use the variables
      instance = child_klass.new("parent value", "child value")
      instance.use_undeclared_parent_var
      instance.use_undeclared_child_var
      instance.use_misspelled_parent_var
      instance.use_misspelled_child_var
      instance.use_parent_var
    end

    # Check that warnings were generated for undeclared/misspelled variables

    # Check for warnings about undeclared variables
    assert_match(/unknown instance variable @parent_undeclared/, stderr_output,
      "Should warn about undeclared parent variable")
    assert_match(/unknown instance variable @child_undeclared/, stderr_output,
      "Should warn about undeclared child variable")

    # Check for warnings about misspelled variables
    assert_match(/unknown instance variable @parent_declraed/, stderr_output,
      "Should warn about misspelled parent variable")
    assert_match(/unknown instance variable @child_declraed/, stderr_output,
      "Should warn about misspelled child variable")

    # Check that no warnings were generated for declared variables
    refute_match(/unknown instance variable @parent_declared/, stderr_output,
      "Should not warn about declared parent variable")
    refute_match(/unknown instance variable @child_declared/, stderr_output,
      "Should not warn about declared child variable")
  end

  def test_no_warnings_for_inherited_variables
    # Create a parent class with positional initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare parent instance variables with positional initialization
      ivar :@parent_var1, init: :positional
      ivar :@parent_var2, init: :positional

      def initialize
        # Values should be set from positional arguments
      end

      def parent_values
        [@parent_var1, @parent_var2]
      end
    end

    # Create a child class that inherits
    child_klass = Class.new(parent_klass) do
      # Declare child instance variables with positional initialization
      ivar :@child_var1, init: :positional
      ivar :@child_var2, init: :positional

      def initialize
        super
      end

      def child_values
        [@child_var1, @child_var2]
      end

      def modify_parent_vars
        # Modify parent variables (should NOT trigger warnings)
        @parent_var1 = @parent_var1.to_s.upcase
        @parent_var2 = @parent_var2.to_s.upcase
      end

      def all_values
        parent_values + child_values
      end
    end

    # Create an instance and modify parent variables
    instance = child_klass.new("parent1", "parent2", "child1", "child2")

    # Capture stderr output when modifying parent variables
    stderr_output = capture_stderr do
      instance.modify_parent_vars
      instance.all_values
    end

    # Check that no warnings were generated for inherited variables
    refute_match(/unknown instance variable @parent_var1/, stderr_output,
      "Should not warn about inherited parent variable @parent_var1")
    refute_match(/unknown instance variable @parent_var2/, stderr_output,
      "Should not warn about inherited parent variable @parent_var2")
  end
end
