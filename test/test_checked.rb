# frozen_string_literal: true

require_relative "test_helper"

class TestChecked < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_automatic_check_ivars
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Checked

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

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
      # Create an instance - this should automatically call check_ivars
      klass.new
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)
  end

  def test_inheritance_with_checked
    # Create a parent class with Checked
    parent_klass = Class.new do
      include Ivar::Checked

      def initialize
        @parent_var = "parent"
      end

      def parent_method
        @parent_typo = "typo"
      end
    end

    # Create a child class that inherits from parent
    child_klass = Class.new(parent_klass) do
      def initialize
        super
        @child_var = "child"
      end

      def child_method
        @child_typo = "typo"
      end
    end

    # Force the analysis to be created for parent class
    parent_analysis = Ivar::PrismAnalysis.new(parent_klass)
    def parent_analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@parent_typo, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[parent_klass] = parent_analysis

    # Force the analysis to be created for child class
    child_analysis = Ivar::PrismAnalysis.new(child_klass)
    def child_analysis.ivar_references
      [
        {name: :@parent_var, path: "test_file.rb", line: 1, column: 1},
        {name: :@child_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@parent_typo, path: "test_file.rb", line: 3, column: 1},
        {name: :@child_typo, path: "test_file.rb", line: 4, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[child_klass] = child_analysis

    # Capture stderr output
    warnings = capture_stderr do
      # Create an instance of the child class - this should automatically call check_ivars
      child_klass.new
    end

    # Check that we got warnings about the typos
    assert_match(/unknown instance variable @parent_typo/, warnings)
    assert_match(/unknown instance variable @child_typo/, warnings)
  end

  def test_checked_warns_for_every_instance
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Checked

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

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

    # First instance - should emit warnings
    first_warnings = capture_stderr do
      klass.new
    end

    # Second instance - should also emit warnings (since Checked doesn't cache)
    second_warnings = capture_stderr do
      klass.new
    end

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we got warnings for the second instance too (since Checked doesn't cache)
    assert_match(/unknown instance variable @typo_veriable/, second_warnings)
  end

  def test_checked_with_warn_once_policy_warns_only_once_per_class
    # Create a class with a typo in an instance variable
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

    # First instance - should emit warnings
    first_warnings = capture_stderr do
      klass.new
    end

    # Second instance - should not emit warnings
    second_warnings = capture_stderr do
      klass.new
    end

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we didn't get warnings for the second instance
    assert_empty second_warnings
  end
end
