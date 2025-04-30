# frozen_string_literal: true

require_relative "validation"

module Ivar
  # Common module with shared functionality for automatic instance variable checking
  module AutoCheckCommon
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
  end

  # Provides automatic validation for instance variables
  # When included, automatically calls check_ivars after initialization
  module Checked
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.extend(AutoCheckCommon::ClassMethods)

      # Create an InstanceMethods module for this specific checker
      instance_methods = Module.new do
        # Wrap the initialize method to automatically call check_ivars
        define_method(:initialize) do |*args, **kwargs, &block|
          # Call the original initialize method
          super(*args, **kwargs, &block)
          # Automatically check instance variables
          check_ivars
        end
      end

      # Store the InstanceMethods module as a constant in the base class
      base.const_set(:InstanceMethods, instance_methods)

      # Prepend the InstanceMethods module to the base class
      base.prepend(instance_methods)
    end
  end

  # Provides automatic validation for instance variables, but only once per class
  # When included, automatically calls check_ivars_once after initialization
  module CheckedOnce
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.extend(AutoCheckCommon::ClassMethods)

      # Create an InstanceMethods module for this specific checker
      instance_methods = Module.new do
        # Wrap the initialize method to automatically call check_ivars_once
        define_method(:initialize) do |*args, **kwargs, &block|
          # Call the original initialize method
          super(*args, **kwargs, &block)
          # Automatically check instance variables once
          check_ivars_once
        end
      end

      # Store the InstanceMethods module as a constant in the base class
      base.const_set(:InstanceMethods, instance_methods)

      # Prepend the InstanceMethods module to the base class
      base.prepend(instance_methods)
    end
  end
end
