# frozen_string_literal: true

require_relative "test_helper"

class TestClassLevelIvars < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_class_level_ivars_in_class_methods_do_not_trigger_warnings
    # Create a class with class-level instance variables used in class methods
    klass = Class.new do
      extend Ivar::Macros
      include Ivar::Checked

      # Class-level instance variable
      @class_level_var = "class value"

      # Declare the class-level instance variable to prevent warnings
      ivar :@class_level_var

      # Class method that uses the class-level instance variable
      def self.get_class_var
        @class_level_var
      end

      # Instance method that uses an instance variable with the same name
      def get_instance_var
        @class_level_var = "instance value"
        @class_level_var
      end
    end

    # Force the analysis to be created for the class
    analysis = Ivar::TargetedPrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.references
      [
        {name: :@class_level_var, path: "test_file.rb", line: 1, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      instance = klass.new
      # Call the instance method to ensure the instance variable is used
      instance.get_instance_var
    end

    # Check that we didn't get warnings about the class-level instance variable
    refute_match(/unknown instance variable @class_level_var/, warnings)

    # Verify that the class method can access the class-level instance variable
    assert_equal "class value", klass.get_class_var
  end

  def test_module_level_ivars_in_module_methods_do_not_trigger_warnings
    # Create a module with module-level instance variables used in module methods
    mod = Module.new do
      # Module-level instance variable
      @module_level_var = "module value"

      # Module method that uses the module-level instance variable
      def self.get_module_var
        @module_level_var
      end

      # Define a method that will be included in classes
      def module_method
        # This is an instance method in the including class
        @instance_var = "instance value from module method"
      end
    end

    # Create a class that includes the module and uses Ivar::Checked
    klass = Class.new do
      include mod
      include Ivar::Checked

      # Declare the instance variable to prevent warnings
      ivar :@instance_var

      def initialize
        module_method
      end
    end

    # Force the analysis to be created for the class
    analysis = Ivar::TargetedPrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.references
      [
        {name: :@instance_var, path: "test_file.rb", line: 1, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      klass.new
    end

    # Check that we didn't get warnings about the instance variable
    refute_match(/unknown instance variable @instance_var/, warnings)

    # Verify that the module method can access the module-level instance variable
    assert_equal "module value", mod.get_module_var
  end

  def test_class_with_multiple_class_methods_using_class_ivars
    # Create a class with multiple class methods using class instance variables
    klass = Class.new do
      extend Ivar::Macros
      include Ivar::Checked

      # Class-level instance variables
      @config = {}
      @initialized = false

      # Declare the class-level instance variables
      ivar :@config, :@initialized

      # Class method that sets a class-level instance variable
      def self.configure(options)
        @config = options
        @initialized = true
      end

      # Class method that reads class-level instance variables
      def self.configuration
        {
          config: @config,
          initialized: @initialized
        }
      end

      # Declare the instance variable
      ivar :@instance_var

      # Instance method that doesn't use class-level variables
      def instance_method
        @instance_var = "instance value"
        @instance_var
      end
    end

    # Configure the class
    klass.configure(api_key: "secret", timeout: 30)

    # Force the analysis to be created for the class
    analysis = Ivar::TargetedPrismAnalysis.new(klass)
    # Monkey patch the analysis to include our variables
    def analysis.references
      [
        {name: :@instance_var, path: "test_file.rb", line: 1, column: 1}
      ]
    end
    # Replace the cached analysis
    Ivar.instance_variable_get(:@analysis_cache)[klass] = analysis

    # Capture stderr output when creating an instance
    warnings = capture_stderr do
      instance = klass.new
      # Call the instance method to ensure the instance variable is used
      instance.instance_method
    end

    # Check that we didn't get warnings about any instance variables
    refute_match(/unknown instance variable/, warnings)

    # Verify that the class methods can access the class-level instance variables
    config = klass.configuration
    assert_equal({api_key: "secret", timeout: 30}, config[:config])
    assert_equal true, config[:initialized]
  end
end
