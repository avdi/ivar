# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module IvarMacros
    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      # Store pre-declared instance variables for this class
      base.instance_variable_set(:@pre_declared_ivars, [])
    end

    # Declares instance variables that should be pre-initialized to nil
    # before the initializer is called
    # @param ivars [Array<Symbol>] Instance variables to pre-initialize
    def ivar(*ivars)
      # Store the pre-declared instance variables
      pre_declared = instance_variable_get(:@pre_declared_ivars) || []
      instance_variable_set(:@pre_declared_ivars, pre_declared + ivars)
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy pre-declared instance variables to subclass
      parent_ivars = instance_variable_get(:@pre_declared_ivars) || []
      subclass.instance_variable_set(:@pre_declared_ivars, parent_ivars.dup)
    end

    # Get the pre-declared instance variables for this class
    # @return [Array<Symbol>] Pre-declared instance variables
    def pre_declared_ivars
      instance_variable_get(:@pre_declared_ivars) || []
    end
  end

  # Module to pre-initialize instance variables
  module PreInitializeIvars
    # Initialize pre-declared instance variables to nil
    def initialize_pre_declared_ivars
      klass = self.class
      while klass.respond_to?(:pre_declared_ivars)
        klass.pre_declared_ivars.each do |ivar|
          instance_variable_set(ivar, nil) unless instance_variable_defined?(ivar)
        end
        klass = klass.superclass
      end
    end
  end
end
