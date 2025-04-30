# frozen_string_literal: true

require_relative "test_helper"

class TestIvarMacros < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_ivar_macro_pre_initializes_variables
    # Create a class with the ivar macro
    klass = Class.new do
      include Ivar::Checked

      ivar :@pre_initialized_var1, :@pre_initialized_var2

      def initialize
        # We don't set @pre_initialized_var1 or @pre_initialized_var2 here
        @normal_var = "normal"
      end

      def method_with_pre_initialized_vars
        # These should be pre-initialized to nil
        [@pre_initialized_var1, @pre_initialized_var2, @normal_var]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the pre-initialized variables exist and are nil
    values = instance.method_with_pre_initialized_vars
    assert_nil values[0], "@pre_initialized_var1 should be nil"
    assert_nil values[1], "@pre_initialized_var2 should be nil"
    assert_equal "normal", values[2], "@normal_var should be 'normal'"
  end

  def test_ivar_macro_with_checked_once
    # Create a class with the ivar macro
    klass = Class.new do
      include Ivar::CheckedOnce

      ivar :@pre_initialized_var

      def initialize
        # We don't set @pre_initialized_var here
        @normal_var = "normal"
      end

      def method_with_pre_initialized_var
        # This should be pre-initialized to nil
        [@pre_initialized_var, @normal_var]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the pre-initialized variable exists and is nil
    values = instance.method_with_pre_initialized_var
    assert_nil values[0], "@pre_initialized_var should be nil"
    assert_equal "normal", values[1], "@normal_var should be 'normal'"
  end

  def test_ivar_macro_with_inheritance
    # Create a parent class with the ivar macro
    parent_klass = Class.new do
      include Ivar::Checked

      ivar :@parent_pre_initialized_var

      def initialize
        @parent_normal_var = "parent normal"
      end
    end

    # Create a child class that inherits the ivar macro
    child_klass = Class.new(parent_klass) do
      ivar :@child_pre_initialized_var

      def initialize
        super
        @child_normal_var = "child normal"
      end

      def method_with_pre_initialized_vars
        [
          @parent_pre_initialized_var,
          @parent_normal_var,
          @child_pre_initialized_var,
          @child_normal_var
        ]
      end
    end

    # Create an instance of the child class
    instance = child_klass.new

    # Check that all pre-initialized variables exist and are nil
    values = instance.method_with_pre_initialized_vars
    assert_nil values[0], "@parent_pre_initialized_var should be nil"
    assert_equal "parent normal", values[1], "@parent_normal_var should be 'parent normal'"
    assert_nil values[2], "@child_pre_initialized_var should be nil"
    assert_equal "child normal", values[3], "@child_normal_var should be 'child normal'"
  end

  def test_ivar_macro_prevents_warnings
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Checked

      ivar :@pre_initialized_var

      def initialize
        @normal_var = "normal"
      end

      def method_with_typo
        # This should not trigger a warning because it's pre-initialized
        @pre_initialized_var = "value"
        # This would trigger a warning if it wasn't for the ivar macro
        @pre_initialized_var.upcase
      end
    end

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.ivar_references
      [
        {name: :@normal_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@pre_initialized_var, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create an instance - this should automatically call check_ivars
    klass.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we didn't get warnings about the pre-initialized variable
    refute_match(/unknown instance variable @pre_initialized_var/, warnings)
  end
end
