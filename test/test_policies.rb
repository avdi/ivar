# frozen_string_literal: true

require_relative "test_helper"
require "logger"

class TestPolicies < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_warn_policy
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output
    warnings = capture_stderr do
      # Call check_ivars with warn policy
      instance.check_ivars(policy: :warn)
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)
  end

  def test_warn_once_policy
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # First call to check_ivars with warn_once policy
    first_warnings = capture_stderr do
      instance.check_ivars(policy: :warn_once)
    end

    # Second call to check_ivars with warn_once policy
    second_warnings = capture_stderr do
      instance.check_ivars(policy: :warn_once)
    end

    # Check that we got warnings for the first call
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we didn't get warnings for the second call
    assert_empty second_warnings
  end

  def test_raise_policy
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Check that calling check_ivars with raise policy raises an exception
    error = assert_raises(NameError) do
      instance.check_ivars(policy: :raise)
    end

    # Check that the error message contains the typo
    assert_match(/unknown instance variable @typo_veriable/, error.message)
  end

  def test_log_policy
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Create a logger that writes to a string
    log_output = StringIO.new
    logger = Logger.new(log_output)

    # Call check_ivars with log policy
    instance.check_ivars(policy: [:log, {logger: logger}])

    # Check that the log contains the typo
    assert_match(/unknown instance variable @typo_veriable/, log_output.string)
  end

  def test_class_level_policy
    # Create a class with a typo and a class-level policy
    klass = Class.new do
      include Ivar::Validation
      extend Ivar::CheckPolicy

      # Set the class-level policy to warn
      ivar_check_policy :warn

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output
    warnings = capture_stderr do
      # Call check_ivars without specifying a policy - should use the class-level policy
      instance.check_ivars
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)
  end

  def test_global_policy
    # Save the original global policy
    original_policy = Ivar.check_policy

    begin
      # Set the global policy to raise
      Ivar.check_policy = :raise

      # Create a class with a typo
      klass = Class.new do
        include Ivar::Validation

        def initialize
          @correct = "value"
        end

        def method_with_typo
          @typo_veriable = "misspelled"
        end
      end

      # Create an instance to define the class
      instance = klass.new

      # Force the analysis to be created and include our method
      analysis = Ivar::PrismAnalysis.new(klass)
      # Monkey patch the analysis to include our typo
      def analysis.ivar_references
        [
          {name: :@correct, path: "test_file.rb", line: 1, column: 1},
          {name: :@typo_veriable, path: "test_file.rb", line: 2, column: 1}
        ]
      end
      # Replace the cached analysis
      Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

      # Check that calling check_ivars without specifying a policy raises an exception
      error = assert_raises(NameError) do
        instance.check_ivars
      end

      # Check that the error message contains the typo
      assert_match(/unknown instance variable @typo_veriable/, error.message)
    ensure
      # Restore the original global policy
      Ivar.check_policy = original_policy
    end
  end

  def test_policy_inheritance
    # Create a parent class with a policy
    parent_klass = Class.new do
      include Ivar::Validation
      extend Ivar::CheckPolicy

      # Set the class-level policy to warn
      ivar_check_policy :warn

      def initialize
        @parent_var = "parent"
      end
    end

    # Create a child class that inherits the policy
    child_klass = Class.new(parent_klass) do
      def initialize
        super
        @child_var = "child"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance of the child class
    instance = child_klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(child_klass)
    # Monkey patch the analysis to include our typo
    def analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@child_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@typo_veriable, path: "test_file.rb", line: 3, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[child_klass] = analysis

    # Capture stderr output
    warnings = capture_stderr do
      # Call check_ivars without specifying a policy - should use the inherited policy
      instance.check_ivars
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)
  end

  def test_checked_module_sets_warn_policy
    # Create a class that includes Checked
    klass = Class.new do
      include Ivar::Checked

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Check that the class has the warn policy
    assert_equal :warn, klass.ivar_check_policy
  end

  def test_checked_with_warn_once_policy
    # Create a class that includes Checked with warn_once policy
    klass = Class.new do
      include Ivar::Checked
      ivar_check_policy :warn_once

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Check that the class has the warn_once policy
    assert_equal :warn_once, klass.ivar_check_policy
  end
end
