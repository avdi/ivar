# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # Special flag object to detect when a parameter is not provided
    UNSET = Object.new.freeze

    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      # Store declared instance variables for this class
      base.instance_variable_set(:@__ivar_declared_ivars, [])
      # Store initial values for declared instance variables
      base.instance_variable_set(:@__ivar_initial_values, {})

      # Declare the internal instance variables used by this module
      # This prevents warnings about unknown instance variables
      if base.respond_to?(:ivar)
        # Add the module's own internal instance variables to the declared list
        base.ivar :@__ivar_declared_ivars, :@__ivar_initial_values
      end
    end

    # Declares instance variables that should be considered valid
    # without being explicitly initialized
    # @param ivars [Array<Symbol>] Instance variables to declare
    # @param value [Object] Optional value to initialize all declared variables with
    #   Example: ivar :@foo, :@bar, value: 123
    # @param ivar_values [Hash] Individual initial values for instance variables
    #   Example: ivar "@foo": 123, "@bar": 456
    # @yield [varname] Block to generate initial values based on variable name
    #   Example: ivar(:@foo, :@bar) { |varname| "#{varname} default" }
    def ivar(*ivars, value: UNSET, **ivar_values, &block)
      # Handle both regular declarations and declarations with initial values
      declared = instance_variable_get(:@__ivar_declared_ivars) || []
      initial_values = instance_variable_get(:@__ivar_initial_values) || {}

      # Process regular declarations (symbols)
      new_ivars = ivars.map(&:to_sym)
      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)

      # If a block is given, use it to generate initial values for each variable
      if block_given?
        new_ivars.each do |ivar_name|
          initial_values[ivar_name] = yield(ivar_name.to_s)
        end
      # If the value: parameter was explicitly provided (even if it's nil or false),
      # apply it to all declared variables
      elsif value != UNSET
        new_ivars.each do |ivar_name|
          initial_values[ivar_name] = value
        end
      end

      # Process declarations with individual initial values (hash)
      ivar_values.each do |key, val|
        # Handle string keys like "@name" by converting to symbols :@name
        ivar_name = key.is_a?(String) ? key.to_sym : key
        initial_values[ivar_name] = val
        # Also add to declared ivars if not already included
        unless declared.include?(ivar_name) || new_ivars.include?(ivar_name)
          new_ivars << ivar_name
        end
      end

      # Update the declared ivars and initial values
      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)
      instance_variable_set(:@__ivar_initial_values, initial_values)
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy declared instance variables to subclass
      parent_ivars = instance_variable_get(:@__ivar_declared_ivars) || []
      subclass.instance_variable_set(:@__ivar_declared_ivars, parent_ivars.dup)

      # Copy initial values to subclass
      parent_values = instance_variable_get(:@__ivar_initial_values) || {}
      subclass.instance_variable_set(:@__ivar_initial_values, parent_values.dup)

      # Declare the internal instance variables in the subclass
      # This prevents warnings about unknown instance variables
      if subclass.respond_to?(:ivar)
        # Add the module's own internal instance variables to the declared list
        subclass.ivar :@__ivar_declared_ivars, :@__ivar_initial_values
      end
    end

    # Get the declared instance variables for this class
    # @return [Array<Symbol>] Declared instance variables
    def ivar_declared
      instance_variable_get(:@__ivar_declared_ivars) || []
    end

    # Get the initial values for declared instance variables
    # @return [Hash] Initial values for declared instance variables
    def ivar_initial_values
      instance_variable_get(:@__ivar_initial_values) || {}
    end
  end
end
