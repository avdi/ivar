# frozen_string_literal: true

require_relative "test_helper"

class TestIvarWithPositionalInitOrdering < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_positional_args_ordering_within_class
    # Create a class with ivars declared in a specific order
    klass = Class.new do
      include Ivar::Checked

      ivar :@first, init: :positional
      ivar :@second, init: :positional
      ivar :@third, init: :positional

      def values
        [@first, @second, @third]
      end
    end

    # Create an instance with positional arguments
    instance = klass.new("value 1", "value 2", "value 3")

    assert_equal ["value 1", "value 2", "value 3"], instance.values
  end

  def test_positional_args_ordering_with_inheritance
    # Create a parent class with positional initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare parent instance variables with positional initialization
      ivar :@parent_first, init: :positional
      ivar :@parent_second, init: :positional

      def parent_values
        [@parent_first, @parent_second]
      end
    end

    # Create a child class with positional initialization
    child_klass = Class.new(parent_klass) do
      # Declare child instance variables with positional initialization
      ivar :@child_first, init: :positional
      ivar :@child_second, init: :positional

      def child_values
        [@child_first, @child_second]
      end

      def all_values
        parent_values + child_values
      end
    end

    # Create an instance with positional arguments
    # Parent vars should be assigned first, then child vars
    instance = child_klass.new("parent 1", "parent 2", "child 1", "child 2")

    # Check that the instance variables were initialized in the correct order
    # (parent vars first, then child vars)
    expected = ["parent 1", "parent 2", "child 1", "child 2"]
    assert_equal expected, instance.all_values
  end

  def test_positional_args_ordering_with_multiple_inheritance_levels
    # Create a grandparent class with positional initialization
    grandparent_klass = Class.new do
      include Ivar::Checked

      # Declare grandparent instance variables with positional initialization
      ivar :@grandparent_var, init: :positional

      def grandparent_values
        [@grandparent_var]
      end
    end

    # Create a parent class with positional initialization
    parent_klass = Class.new(grandparent_klass) do
      # Declare parent instance variables with positional initialization
      ivar :@parent_var, init: :positional

      def parent_values
        [@parent_var]
      end
    end

    # Create a child class with positional initialization
    child_klass = Class.new(parent_klass) do
      # Declare child instance variables with positional initialization
      ivar :@child_var, init: :positional

      def child_values
        [@child_var]
      end

      def all_values
        grandparent_values + parent_values + child_values
      end
    end

    # Create an instance with positional arguments
    # Vars should be assigned in order: grandparent, parent, child
    instance = child_klass.new("grandparent value", "parent value", "child value")

    # Check that the instance variables were initialized in the correct order
    expected = ["grandparent value", "parent value", "child value"]
    assert_equal expected, instance.all_values
  end

  def test_positional_args_ordering_with_inheritance_and_overrides
    skip "skip positional tests for now"
    # Create a parent class with positional initialization
    parent_klass = Class.new do
      include Ivar::Checked

      # Declare parent instance variables with positional initialization
      ivar :@var1, init: :positional
      ivar :@var2, init: :positional
      ivar :@var3, init: :positional

      def values
        [@var1, @var2, @var3]
      end
    end

    # Create a child class that overrides some parent variables
    child_klass = Class.new(parent_klass) do
      # Override var2 with a different default
      ivar :@var2, value: "child default for var2"

      # Add a new positional var
      ivar :@var4, init: :positional

      def all_values
        values + [@var4]
      end
    end

    # Create an instance with positional arguments
    # The order should be: var1, var2, var3 (from parent), var4 (from child)
    instance = child_klass.new("value 1", "value 2", "value 3", "value 4")

    # Check that the instance variables were initialized in the correct order
    expected = ["value 1", "value 2", "value 3", "value 4"]
    assert_equal expected, instance.all_values
  end

  def test_positional_args_ordering_with_mixed_initialization_types
    # Create a class with mixed initialization types
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with different initialization methods
      ivar :@pos1, init: :positional
      ivar :@regular, value: "default"
      ivar :@pos2, init: :positional
      ivar :@kw, init: :kwarg
      ivar :@pos3, init: :positional

      def values
        [@pos1, @pos2, @pos3, @regular, @kw]
      end
    end

    # Create an instance with positional and keyword arguments
    instance = klass.new("value 1", "value 2", "value 3", kw: "kw value")

    # Check that the positional instance variables were initialized in the correct order
    expected = ["value 1", "value 2", "value 3", "default", "kw value"]
    assert_equal expected, instance.values
  end

  def test_positional_args_ordering_with_declaration_order
    # Create a class with ivars declared in a specific order
    klass = Class.new do
      include Ivar::Checked

      # First declaration
      ivar :@first, init: :positional

      # Second declaration
      ivar :@second, init: :positional

      # Third declaration
      ivar :@third, init: :positional

      def values
        [@first, @second, @third]
      end
    end

    # Create an instance with positional arguments
    instance = klass.new("value 1", "value 2", "value 3")

    # Check that the instance variables were initialized in the order they were declared
    assert_equal ["value 1", "value 2", "value 3"], instance.values
  end

  def test_warnings_with_incorrect_positional_args_count
    skip "skip positional tests for now"
    # Create a class with positional initialization
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables with positional initialization
      ivar :@var1, init: :positional
      ivar :@var2, init: :positional
      ivar :@var3, init: :positional

      def initialize
        # Values should be set from positional arguments
      end

      def values
        [@var1, @var2, @var3]
      end
    end

    # Create an instance with too few positional arguments
    # This should not cause a warning about undeclared variables,
    # but the missing variables should be nil
    instance_with_too_few = klass.new("value 1")
    values_with_too_few = instance_with_too_few.values

    # Capture stderr to check for warnings
    stderr_output = capture_stderr do
      # Access the values to ensure the variables are used
      instance_with_too_few.values
    end

    # Check that no warnings were generated for declared variables
    refute_match(/unknown instance variable @var1/, stderr_output, "Should not warn about declared variable @var1")
    refute_match(/unknown instance variable @var2/, stderr_output, "Should not warn about declared variable @var2")
    refute_match(/unknown instance variable @var3/, stderr_output, "Should not warn about declared variable @var3")

    # Check that the missing variables are nil
    assert_equal "value 1", values_with_too_few[0]
    assert_nil values_with_too_few[1]
    assert_nil values_with_too_few[2]

    # Create an instance with too many positional arguments
    # This should not cause a warning, but the extra arguments should be passed to initialize
    instance_with_too_many = klass.new("value 1", "value 2", "value 3", "extra 1", "extra 2")
    values_with_too_many = instance_with_too_many.values

    # Check that no warnings were generated
    stderr_output = capture_stderr do
      # Access the values to ensure the variables are used
      instance_with_too_many.values
    end
    assert_empty stderr_output, "Should not generate any warnings for extra arguments"

    # Check that the variables were set correctly
    assert_equal ["value 1", "value 2", "value 3"], values_with_too_many
  end

  def test_warnings_for_undeclared_variables_in_ordering_context
    skip "skip positional tests for now"
    # Create a class with positional initialization in a specific order
    klass = Class.new do
      include Ivar::Checked

      # Declare instance variables in a specific order
      ivar :@first, init: :positional
      ivar :@second, init: :positional
      ivar :@third, init: :positional

      def initialize
        # Use declared variables
        @first = @first.to_s.upcase
        @second = @second.to_s.upcase
        @third = @third.to_s.upcase

        # Use an undeclared variable (should trigger a warning)
        @undeclared = "this should trigger a warning"
      end

      def values
        [@first, @second, @third]
      end

      def use_misspelled_variable
        # Misspelled variable (should trigger a warning)
        @secnod = "misspelled"
      end
    end

    # Create an instance and use the misspelled variable
    instance = klass.new("value 1", "value 2", "value 3")

    # Capture stderr output when using misspelled variable
    stderr_output = capture_stderr do
      instance.use_misspelled_variable
    end

    # Check that warnings were generated for undeclared/misspelled variables
    assert_match(/unknown instance variable @undeclared/, stderr_output, "Should warn about undeclared variable")
    assert_match(/unknown instance variable @secnod/, stderr_output, "Should warn about misspelled variable")

    # Check that no warnings were generated for declared variables
    refute_match(/unknown instance variable @first/, stderr_output, "Should not warn about declared variable @first")
    refute_match(/unknown instance variable @second/, stderr_output, "Should not warn about declared variable @second")
    refute_match(/unknown instance variable @third/, stderr_output, "Should not warn about declared variable @third")
  end
end
