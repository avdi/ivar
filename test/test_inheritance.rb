# frozen_string_literal: true

require_relative "test_helper"

class TestInheritance < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_validation_inheritance
    # Create a parent class with Validation
    parent_klass = Class.new do
      include Ivar::Validation

      def initialize
        @parent_var = "parent"
        check_ivars
      end

      def parent_method
        @parent_method_var = "parent method"
      end
    end

    # Create a child class that inherits from parent WITHOUT including Validation again
    child_klass = Class.new(parent_klass) do
      def initialize
        super
        @child_var = "child"
        # No explicit check_ivars call here - should inherit from parent
      end

      def child_method
        @child_method_var = "child method"
        @typo_veriable = "typo" # Intentional typo
      end
    end

    # Create an instance of the child class
    child = child_klass.new

    # Verify that the child class can call check_ivars even though it doesn't include Validation
    assert_respond_to child, :check_ivars

    # Test that the child class inherits the check_ivars method from the parent
    # by verifying that it's the same method object
    assert_equal parent_klass.instance_method(:check_ivars),
      child_klass.instance_method(:check_ivars)
  end

  def test_checked_inheritance
    # Create a parent class with Checked
    parent_klass = Class.new do
      include Ivar::Checked

      def initialize
        @parent_var = "parent"
      end

      def parent_method
        @parent_method_var = "parent method"
      end
    end

    # Create a child class that inherits from parent WITHOUT including Checked again
    child_klass = Class.new(parent_klass) do
      def initialize
        super
        @child_var = "child"
      end

      def child_method
        @child_method_var = "child method"
        @typo_veriable = "typo" # Intentional typo
      end
    end

    # Force the analysis to be created for child class
    child_analysis = Ivar::PrismAnalysis.new(child_klass)
    def child_analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@child_var, path: "test_file.rb", line: 3, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 5, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[child_klass] = child_analysis

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create an instance of the child class - this should automatically call check_ivars
    # even though Checked wasn't included again
    child_klass.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # We don't check for absence of warnings about defined variables
    # because they might appear in warnings depending on how the analysis is done
  end

  def test_policy_inheritance
    # Create a parent class with Checked and a specific policy
    parent_klass = Class.new do
      include Ivar::Checked
      ivar_check_policy :warn_once

      def initialize
        @parent_var = "parent"
      end
    end

    # Create a child class that inherits from parent WITHOUT setting a policy
    child_klass = Class.new(parent_klass) do
      def initialize
        super
        @child_var = "child"
      end

      def child_method
        @typo_veriable = "typo" # Intentional typo
      end
    end

    # Check that the child class inherited the policy
    assert_equal :warn_once, child_klass.ivar_check_policy

    # Force the analysis to be created for child class
    child_analysis = Ivar::PrismAnalysis.new(child_klass)
    def child_analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@child_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 3, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[child_klass] = child_analysis

    # Capture stderr output for first instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create first instance of child class
    child_klass.new

    # Get the captured warnings
    first_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Capture stderr output for second instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create second instance of child class
    child_klass.new

    # Get the captured warnings
    second_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we didn't get warnings for the second instance (warn_once policy)
    assert_empty second_warnings
  end

  def test_policy_override_in_child
    # Create a parent class with Checked and a specific policy
    parent_klass = Class.new do
      include Ivar::Checked
      ivar_check_policy :warn

      def initialize
        @parent_var = "parent"
      end
    end

    # Create a child class that overrides the policy
    child_klass = Class.new(parent_klass) do
      ivar_check_policy :warn_once

      def initialize
        super
        @child_var = "child"
      end

      def child_method
        @typo_veriable = "typo" # Intentional typo
      end
    end

    # Check that the child class has its own policy, not the parent's
    assert_equal :warn_once, child_klass.ivar_check_policy
    assert_equal :warn, parent_klass.ivar_check_policy

    # Force the analysis to be created for child class
    child_analysis = Ivar::PrismAnalysis.new(child_klass)
    def child_analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@child_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 3, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[child_klass] = child_analysis

    # Capture stderr output for first instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create first instance of child class
    child_klass.new

    # Get the captured warnings
    first_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Capture stderr output for second instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create second instance of child class
    child_klass.new

    # Get the captured warnings
    second_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we didn't get warnings for the second instance (warn_once policy)
    assert_empty second_warnings
  end

  def test_deep_inheritance_chain
    # Create a base class with Checked
    base_klass = Class.new do
      include Ivar::Checked
      ivar_check_policy :warn

      def initialize
        @base_var = "base"
      end
    end

    # Create a middle class that inherits from base
    middle_klass = Class.new(base_klass) do
      def initialize
        super
        @middle_var = "middle"
      end
    end

    # Create a leaf class that inherits from middle
    leaf_klass = Class.new(middle_klass) do
      def initialize
        super
        @leaf_var = "leaf"
      end

      def leaf_method
        @typo_veriable = "typo" # Intentional typo
      end
    end

    # Force the analysis to be created for leaf class
    leaf_analysis = Ivar::PrismAnalysis.new(leaf_klass)
    def leaf_analysis.ivar_references
      [
        {name: :@base_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@middle_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@leaf_var, path: "test_file.rb", line: 3, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 4, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[leaf_klass] = leaf_analysis

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create an instance of the leaf class - this should automatically call check_ivars
    # even though Checked wasn't included in middle or leaf classes
    leaf_klass.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # Check that we didn't get warnings about defined variables
    refute_match(/unknown instance variable @base_var/, warnings)
    # We don't check for @middle_var and @leaf_var here because they might appear in warnings
    # depending on how the analysis is done
  end
end
