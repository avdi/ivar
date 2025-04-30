# frozen_string_literal: true

require_relative "test_helper"

class TestCheckIvarsOnce < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_check_ivars_once_warns_on_first_call
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

    # Create an instance to define the class and add methods to the analysis
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
    original_stderr = $stderr
    $stderr = StringIO.new

    # Call check_ivars_once to validate
    instance.check_ivars_once

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)
  end

  def test_check_ivars_once_does_not_warn_on_subsequent_calls
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

    # First call to check_ivars_once (should emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance.check_ivars_once
    first_warnings = $stderr.string
    $stderr = original_stderr

    # Second call to check_ivars_once (should not emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance.check_ivars_once
    second_warnings = $stderr.string
    $stderr = original_stderr

    # Check that we got warnings the first time
    assert_match(/unknown instance variable @typo_veriable/, first_warnings)

    # Check that we didn't get warnings the second time
    assert_empty second_warnings
  end

  def test_different_classes_are_tracked_separately
    # Create two classes with typos
    klass1 = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_in_class1 = "misspelled"
      end
    end

    klass2 = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_typo
        @typo_in_class2 = "misspelled"
      end
    end

    # Create instances of both classes
    instance1 = klass1.new
    instance2 = klass2.new

    # Force the analysis to be created for klass1
    analysis1 = Ivar::PrismAnalysis.new(klass1)
    # Monkey patch the analysis to include our typo
    def analysis1.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_in_class1, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass1] = analysis1

    # Force the analysis to be created for klass2
    analysis2 = Ivar::PrismAnalysis.new(klass2)
    # Monkey patch the analysis to include our typo
    def analysis2.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@typo_in_class2, path: "test_file.rb", line: 2, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass2] = analysis2

    # First call to check_ivars_once for instance1 (should emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance1.check_ivars_once
    first_class_warnings = $stderr.string
    $stderr = original_stderr

    # First call to check_ivars_once for instance2 (should emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance2.check_ivars_once
    second_class_warnings = $stderr.string
    $stderr = original_stderr

    # Check that we got warnings for the first class
    assert_match(/unknown instance variable @typo_in_class1/, first_class_warnings)

    # Check that we got warnings for the second class
    assert_match(/unknown instance variable @typo_in_class2/, second_class_warnings)

    # Second call to check_ivars_once for instance1 (should not emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance1.check_ivars_once
    first_class_second_call = $stderr.string
    $stderr = original_stderr

    # Second call to check_ivars_once for instance2 (should not emit warnings)
    original_stderr = $stderr
    $stderr = StringIO.new
    instance2.check_ivars_once
    second_class_second_call = $stderr.string
    $stderr = original_stderr

    # Check that we didn't get warnings for either class on the second call
    assert_empty first_class_second_call
    assert_empty second_class_second_call
  end

  def test_check_ivars_once_with_additional_variables
    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
      end

      def method_with_vars
        @allowed_var = "allowed"
        @unknown_var = "unknown"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Force the analysis to be created and include our method
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.ivar_references
      [
        {name: :@correct, path: "test_file.rb", line: 1, column: 1},
        {name: :@allowed_var, path: "test_file.rb", line: 2, column: 1},
        {name: :@unknown_var, path: "test_file.rb", line: 3, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Call check_ivars_once to validate
    instance.check_ivars_once(add: [:@allowed_var])

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got a warning about the unknown variable
    assert_match(/unknown instance variable @unknown_var/, warnings)

    # Check that we didn't get warnings about allowed variables
    refute_match(/unknown instance variable @allowed_var/, warnings)
  end
end
