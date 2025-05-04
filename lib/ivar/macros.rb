# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      # Store declared instance variables for this class
      base.instance_variable_set(:@__ivar_declared_ivars, [])
    end

    # Declares instance variables that should be considered valid
    # without being explicitly initialized
    # @param ivars [Array<Symbol>] Instance variables to declare
    def ivar(*ivars)
      # Store the declared instance variables
      declared = instance_variable_get(:@__ivar_declared_ivars) || []
      instance_variable_set(:@__ivar_declared_ivars, declared + ivars)
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy declared instance variables to subclass
      parent_ivars = instance_variable_get(:@__ivar_declared_ivars) || []
      subclass.instance_variable_set(:@__ivar_declared_ivars, parent_ivars.dup)
    end

    # Get the declared instance variables for this class
    # @return [Array<Symbol>] Declared instance variables
    def ivar_declared
      instance_variable_get(:@__ivar_declared_ivars) || []
    end
  end

  # Legacy module kept for backward compatibility
  # No longer initializes instance variables to nil
  module PreInitializeIvars
    # This method is now a no-op for backward compatibility
    def initialize_pre_declared_ivars
      # No longer initializes instance variables to nil
    end
  end
end
