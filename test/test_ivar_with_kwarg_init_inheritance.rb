# frozen_string_literal: true

require "test_helper"

class TestIvarWithKwargInitInheritance < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_ivar_with_kwarg_init_inheritance_defaults_and_overrides
    # Parent class with kwarg initialization and defaults
    parent_class = Class.new do
      include Ivar::Checked

      # Declare instance variables with kwarg initialization and defaults
      ivar :@parent_var1, init: :kwarg, value: "parent default 1"
      ivar :@parent_var2, init: :kwarg, value: "parent default 2"
      ivar :@shared_var, init: :kwarg, value: "parent shared default"

      def initialize(extra_arg: nil)
        @extra_parent = extra_arg
      end

      def values
        {
          parent_var1: @parent_var1,
          parent_var2: @parent_var2,
          shared_var: @shared_var,
          extra_parent: @extra_parent
        }
      end
    end

    # Child class that inherits and adds its own kwarg initialization
    child_class = Class.new(parent_class) do
      # Declare child-specific instance variables with kwarg initialization
      ivar :@child_var1, init: :kwarg, value: "child default 1"
      ivar :@child_var2, init: :kwarg, value: "child default 2"

      # Override a parent variable with a different default
      ivar :@shared_var, init: :kwarg, value: "child shared default"

      def initialize(child_extra: nil, **kwargs)
        @child_extra = child_extra
        super(**kwargs)
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

    # Test 1: Create instance with defaults only
    instance1 = child_class.new
    expected1 = {
      parent_var1: "parent default 1",
      parent_var2: "parent default 2",
      shared_var: "child shared default", # Should use child's default
      extra_parent: nil,
      child_var1: "child default 1",
      child_var2: "child default 2",
      child_extra: nil
    }
    assert_equal expected1, instance1.all_values

    # Test 2: Override parent variables
    instance2 = child_class.new(
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2"
    )
    expected2 = {
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2",
      shared_var: "child shared default",
      extra_parent: nil,
      child_var1: "child default 1",
      child_var2: "child default 2",
      child_extra: nil
    }
    assert_equal expected2, instance2.all_values

    # Test 3: Override child variables
    instance3 = child_class.new(
      child_var1: "custom child 1",
      child_var2: "custom child 2"
    )
    expected3 = {
      parent_var1: "parent default 1",
      parent_var2: "parent default 2",
      shared_var: "child shared default",
      extra_parent: nil,
      child_var1: "custom child 1",
      child_var2: "custom child 2",
      child_extra: nil
    }
    assert_equal expected3, instance3.all_values

    # Test 4: Override shared variable
    instance4 = child_class.new(shared_var: "custom shared")

    expected4 = {
      parent_var1: "parent default 1",
      parent_var2: "parent default 2",
      shared_var: "custom shared",
      extra_parent: nil,
      child_var1: "child default 1",
      child_var2: "child default 2",
      child_extra: nil
    }
    assert_equal expected4, instance4.all_values

    # Test 5: Override everything and pass through extra args
    instance5 = child_class.new(
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2",
      shared_var: "custom shared",
      child_var1: "custom child 1",
      child_var2: "custom child 2",
      extra_arg: "parent extra",
      child_extra: "child extra"
    )

    expected5 = {
      parent_var1: "custom parent 1",
      parent_var2: "custom parent 2",
      shared_var: "custom shared",
      extra_parent: "parent extra",
      child_var1: "custom child 1",
      child_var2: "custom child 2",
      child_extra: "child extra"
    }
    assert_equal expected5, instance5.all_values
  end
end
