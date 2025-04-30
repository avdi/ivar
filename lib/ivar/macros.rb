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
      # Store keyword argument mappings
      base.instance_variable_set(:@__ivar_kwarg_mappings, [])
      # Store positional argument mappings
      base.instance_variable_set(:@__ivar_arg_mappings, [])
    end

    # Declares instance variables that should be pre-initialized to nil
    # before the initializer is called
    # @param ivars [Array<Symbol>] Instance variables to pre-initialize
    # @param kwarg [Array<Symbol>] Instance variables to initialize from keyword arguments
    # @param arg [Array<Symbol>] Instance variables to initialize from positional arguments
    # @yield Optional block to execute in the context of the instance before initialization
    def ivar(*ivars, kwarg: [], arg: [], &block)
      # Store the pre-declared instance variables
      pre_declared = instance_variable_get(:@__ivar_pre_declared_ivars) || []
      instance_variable_set(:@__ivar_pre_declared_ivars, pre_declared + ivars)

      # Store the keyword argument mappings
      kwarg_mappings = instance_variable_get(:@__ivar_kwarg_mappings) || []
      instance_variable_set(:@__ivar_kwarg_mappings, kwarg_mappings + Array(kwarg))

      # Store the positional argument mappings
      arg_mappings = instance_variable_get(:@__ivar_arg_mappings) || []
      instance_variable_set(:@__ivar_arg_mappings, arg_mappings + Array(arg))

      # Store the initialization block if provided
      instance_variable_set(:@__ivar_init_block, block) if block
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy pre-declared instance variables to subclass
      parent_ivars = instance_variable_get(:@__ivar_pre_declared_ivars) || []
      subclass.instance_variable_set(:@__ivar_pre_declared_ivars, parent_ivars.dup)

      # Copy keyword argument mappings to subclass
      parent_kwarg_mappings = instance_variable_get(:@__ivar_kwarg_mappings) || []
      subclass.instance_variable_set(:@__ivar_kwarg_mappings, parent_kwarg_mappings.dup)

      # Copy positional argument mappings to subclass
      parent_arg_mappings = instance_variable_get(:@__ivar_arg_mappings) || []
      subclass.instance_variable_set(:@__ivar_arg_mappings, parent_arg_mappings.dup)

      # Copy initialization block to subclass
      parent_block = instance_variable_get(:@__ivar_init_block)
      subclass.instance_variable_set(:@__ivar_init_block, parent_block) if parent_block
    end

    # Get the pre-declared instance variables for this class
    # @return [Array<Symbol>] Pre-declared instance variables
    def pre_declared_ivars
      instance_variable_get(:@__ivar_pre_declared_ivars) || []
    end

    # Get the keyword argument mappings for this class
    # @return [Array<Symbol>] Keyword argument mappings
    def kwarg_mappings
      instance_variable_get(:@__ivar_kwarg_mappings) || []
    end

    # Get the positional argument mappings for this class
    # @return [Array<Symbol>] Positional argument mappings
    def arg_mappings
      instance_variable_get(:@__ivar_arg_mappings) || []
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

    # Get all keyword argument mappings from the class hierarchy
    # @return [Array<Symbol>] All keyword argument mappings
    def all_kwarg_mappings
      mappings = []
      klass = self.class
      while klass.respond_to?(:kwarg_mappings)
        mappings.concat(klass.kwarg_mappings)
        klass = klass.superclass
      end
      mappings
    end

    # Get all positional argument mappings from the class hierarchy
    # @return [Array<Symbol>] All positional argument mappings
    def all_arg_mappings
      mappings = []
      klass = self.class
      while klass.respond_to?(:arg_mappings)
        mappings.concat(klass.arg_mappings)
        klass = klass.superclass
      end
      mappings
    end

    # Initialize instance variables from keyword arguments
    # @param kwargs [Hash] Keyword arguments
    # @return [Hash] Remaining keyword arguments
    def initialize_from_kwargs(kwargs)
      remaining_kwargs = kwargs.dup

      all_kwarg_mappings.each do |ivar|
        # Convert @ivar_name to ivar_name for keyword lookup
        key = ivar.to_s.delete_prefix("@").to_sym

        if remaining_kwargs.key?(key)
          instance_variable_set(ivar, remaining_kwargs[key])
          remaining_kwargs.delete(key)
        end
      end

      remaining_kwargs
    end

    # Initialize instance variables from positional arguments
    # @param args [Array] Positional arguments
    # @return [Array] Remaining positional arguments
    def initialize_from_args(args)
      remaining_args = args.dup

      # Get all positional argument mappings
      mappings = all_arg_mappings

      # Only process if we have mappings and arguments
      return remaining_args if mappings.empty? || remaining_args.empty?

      # Take only as many arguments as we have mappings
      args_to_use = remaining_args.shift(mappings.size)

      # Set instance variables from the arguments
      mappings.each_with_index do |ivar, index|
        instance_variable_set(ivar, args_to_use[index]) if index < args_to_use.size
      end

      remaining_args
    end
  end
end
