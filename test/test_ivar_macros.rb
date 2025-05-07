# frozen_string_literal: true

require_relative "test_helper"

class TestMacros < Minitest::Test
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

  def test_ivar_macro_declares_variables
    # Create a class with the ivar macro
    klass = Class.new do
      include Ivar::Checked

      # Declare variables that might be referenced before being set
      ivar :@declared_var

      def initialize
        # We don't set @declared_var here
        # But we do set these normal variables
        @normal_var1 = "normal1"
        @normal_var2 = "normal2"
      end

      def method_with_vars
        # This should be undefined, not nil
        defined?(@declared_var) ? @declared_var : "undefined"
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the declared variable is undefined (not nil)
    # This is the key change in behavior
    value = instance.method_with_vars
    assert_equal "undefined", value, "@declared_var should be undefined"
  end

  def test_ivar_macro_with_checked_and_warn_once_policy
    # Create a class with the ivar macro
    klass = Class.new do
      include Ivar::Checked
      ivar_check_policy :warn_once

      ivar :@declared_var

      def initialize
        # We don't set @declared_var here
        @normal_var = "normal"
      end

      def method_with_declared_var
        # This should be undefined, not nil
        [defined?(@declared_var) ? @declared_var : "undefined", @normal_var]
      end
    end

    # Create an instance
    instance = klass.new

    # Check that the declared variable is undefined (not nil)
    values = instance.method_with_declared_var
    assert_equal "undefined", values[0], "@declared_var should be undefined"
    assert_equal "normal", values[1], "@normal_var should be 'normal'"
  end

  def test_ivar_macro_with_inheritance
    # Create a parent class with the ivar macro
    parent_klass = Class.new do
      include Ivar::Checked

      ivar :@parent_declared_var

      def initialize
        @parent_normal_var = "parent normal"
      end
    end

    # Create a child class that inherits the ivar macro
    child_klass = Class.new(parent_klass) do
      ivar :@child_declared_var

      def initialize
        super
        @child_normal_var = "child normal"
      end

      def method_with_declared_vars
        [
          defined?(@parent_declared_var) ? @parent_declared_var : "undefined parent",
          @parent_normal_var,
          defined?(@child_declared_var) ? @child_declared_var : "undefined child",
          @child_normal_var
        ]
      end
    end

    # Create an instance of the child class
    instance = child_klass.new

    # Check that declared variables are undefined but don't cause warnings
    values = instance.method_with_declared_vars
    assert_equal "undefined parent", values[0], "@parent_declared_var should be undefined"
    assert_equal "parent normal", values[1], "@parent_normal_var should be 'parent normal'"
    assert_equal "undefined child", values[2], "@child_declared_var should be undefined"
    assert_equal "child normal", values[3], "@child_normal_var should be 'child normal'"
  end

  def test_ivar_macro_prevents_warnings
    # Create a class with a declared instance variable
    klass = Class.new do
      include Ivar::Checked

      ivar :@declared_var

      def initialize
        @normal_var = "normal"
      end

      def method_with_declared_var
        # This should not trigger a warning because it's declared
        # Even though it's not initialized
        @declared_var = "value"
        # This would trigger a warning if it wasn't declared
        @declared_var.upcase
      end
    end

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.references
      [
        {name: :@normal_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@declared_var, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      # Create an instance - this should automatically call check_ivars
      klass.new
    end

    # Check that we didn't get warnings about the declared variable
    refute_match(/unknown instance variable @declared_var/, warnings)
  end
end
