# frozen_string_literal: true

require_relative "test_helper"

class TestClassMethodIvars < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_class_method_ivars_do_not_trigger_warnings
    # Create a class with class methods that reference class-level instance variables
    klass = Class.new do
      extend Ivar::Macros
      include Ivar::Checked

      # Class-level instance variables
      @config = {}
      @initialized = false

      # Class method that uses class-level instance variables
      def self.configure(options)
        @config = options
        @initialized = true
      end

      # Another class method that uses class-level instance variables
      def self.configuration
        {
          config: @config,
          initialized: @initialized
        }
      end

      # Instance method that doesn't use class-level variables
      def instance_method
        @instance_var = "instance value"
      end
    end

    # Configure the class
    klass.configure(api_key: "secret", timeout: 30)

    # Force the analysis to be created for the class with our custom references
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables with context
    def analysis.ivar_references
      [
        # Class method references (should be ignored)
        {name: :@config, path: "test_file.rb", line: 1, column: 1, context: :class},
        {name: :@initialized, path: "test_file.rb", line: 2, column: 1, context: :class},
        # Instance method reference (should be checked)
        {name: :@instance_var, path: "test_file.rb", line: 3, column: 1, context: :instance}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      klass.new
    end

    # Check that we didn't get warnings about the class-level instance variables
    refute_match(/unknown instance variable @config/, warnings)
    refute_match(/unknown instance variable @initialized/, warnings)
    # But we should get a warning about the undeclared instance variable
    assert_match(/unknown instance variable @instance_var/, warnings)

    # Verify that the class methods can access the class-level instance variables
    config = klass.configuration
    assert_equal({api_key: "secret", timeout: 30}, config[:config])
    assert_equal true, config[:initialized]
  end

  def test_instance_method_with_same_name_as_class_ivar_triggers_warning
    # Create a class with both class-level and instance-level variables with the same name
    klass = Class.new do
      extend Ivar::Macros
      include Ivar::Checked

      # Set the check policy to warn (not warn_once) to ensure we get warnings
      ivar_check_policy :warn

      # Class-level instance variable
      @shared_var = "class value"

      # Class method that uses the class-level instance variable
      def self.get_class_var
        @shared_var
      end

      # Instance method that uses an instance variable with the same name
      # but doesn't declare it - should trigger a warning
      def get_instance_var
        @shared_var
      end
    end

    # Force the analysis to be created for the class with our custom references
    analysis = Ivar::PrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables with context
    def analysis.ivar_references
      [
        # Class method reference (should be ignored)
        {name: :@shared_var, path: "test_file.rb", line: 1, column: 1, context: :class},
        # Instance method reference (should trigger warning)
        {name: :@shared_var, path: "test_file.rb", line: 2, column: 1, context: :instance}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      # Create an instance and call the method to ensure the instance variable is used
      klass.new.get_instance_var
    end

    # Check that we got warnings about the undeclared instance variable
    assert_match(/unknown instance variable @shared_var/, warnings)

    # Verify that the class method can access the class-level instance variable
    assert_equal "class value", klass.get_class_var
  end
end
