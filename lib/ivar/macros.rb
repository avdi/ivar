# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      # Store pre-declared instance variables for this class
      base.instance_variable_set(:@__ivar_pre_declared_ivars, [])
      # Store initialization block
      base.instance_variable_set(:@__ivar_init_block, nil)
    end

    # Declares instance variables that should be pre-initialized to nil
    # before the initializer is called
    # @param ivars [Array<Symbol>] Instance variables to pre-initialize
    # @yield Optional block to execute in the context of the instance before initialization
    def ivar(*ivars, &block)
      # Store the pre-declared instance variables
      pre_declared = instance_variable_get(:@__ivar_pre_declared_ivars) || []
      instance_variable_set(:@__ivar_pre_declared_ivars, pre_declared + ivars)

      # Store the initialization block if provided
      instance_variable_set(:@__ivar_init_block, block) if block
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy pre-declared instance variables to subclass
      parent_ivars = instance_variable_get(:@__ivar_pre_declared_ivars) || []
      subclass.instance_variable_set(:@__ivar_pre_declared_ivars, parent_ivars.dup)

      # Copy initialization block to subclass
      parent_block = instance_variable_get(:@__ivar_init_block)
      subclass.instance_variable_set(:@__ivar_init_block, parent_block) if parent_block
    end

    # Get the pre-declared instance variables for this class
    # @return [Array<Symbol>] Pre-declared instance variables
    def pre_declared_ivars
      instance_variable_get(:@__ivar_pre_declared_ivars) || []
    end

    # Get the initialization block for this class
    # @return [Proc, nil] The initialization block or nil if none was provided
    def ivar_init_block
      instance_variable_get(:@__ivar_init_block)
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

    # Execute the initialization block in the context of the instance
    def execute_ivar_init_block
      klass = self.class
      while klass.respond_to?(:ivar_init_block)
        block = klass.ivar_init_block
        instance_eval(&block) if block
        klass = klass.superclass
      end
    end
  end
end
