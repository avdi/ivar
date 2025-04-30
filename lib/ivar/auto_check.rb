# frozen_string_literal: true

require_relative 'validation'

module Ivar
  # Base module for automatic instance variable validation
  # This is not meant to be included directly
  module AutoCheck
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.extend(ClassMethods)
    end

    # Class methods added to the including class
    module ClassMethods
      # Hook method called when the module is included
      def inherited(subclass)
        super
        # Ensure subclasses also get the initialize wrapper
        subclass.prepend(subclass.const_get(:InstanceMethods))
      end
    end

    # Creates a module that will automatically check instance variables
    # @param check_method_name [Symbol] The method to call for checking (check_ivars or check_ivars_once)
    # @return [Module] A module that can be included to automatically check instance variables
    def self.create_checker(check_method_name)
      Module.new do
        # Define a class variable to store the check method
        class << self
          attr_accessor :check_method
        end
        self.check_method = check_method_name

        # When this module is included in a class, it extends the class
        # with ClassMethods and includes the Validation module
        def self.included(base)
          base.include(Validation)
          base.extend(AutoCheck::ClassMethods)

          # Get the check method from the module
          check_method_name = check_method

          # Create an InstanceMethods module for this specific checker
          instance_methods = Module.new do
            # Store the check method name in a local variable for the closure
            method_to_call = check_method_name

            # Wrap the initialize method to automatically call the check method
            define_method(:initialize) do |*args, **kwargs, &block|
              # Call the original initialize method
              super(*args, **kwargs, &block)
              # Automatically check instance variables
              send(method_to_call)
            end
          end

          # Store the InstanceMethods module as a constant in the base class
          base.const_set(:InstanceMethods, instance_methods)

          # Prepend the InstanceMethods module to the base class
          base.prepend(instance_methods)
        end
      end
    end
  end

  # Provides automatic validation for instance variables
  # When included, automatically calls check_ivars after initialization
  Checked = AutoCheck.create_checker(:check_ivars)

  # Provides automatic validation for instance variables, but only once per class
  # When included, automatically calls check_ivars_once after initialization
  CheckedOnce = AutoCheck.create_checker(:check_ivars_once)
end
