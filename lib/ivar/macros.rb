# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # Special flag object to detect when a parameter is not provided
    UNSET = Object.new.freeze

    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      base.instance_variable_set(:@__ivar_declared_ivars, [])
      base.instance_variable_set(:@__ivar_initial_values, {})
      base.instance_variable_set(:@__ivar_init_methods, {})
    end

    # Declares instance variables that should be considered valid
    # without being explicitly initialized
    # @param ivars [Array<Symbol>] Instance variables to declare
    # @param value [Object] Optional value to initialize all declared variables with
    #   Example: ivar :@foo, :@bar, value: 123
    # @param init [Symbol] Initialization method for the variable
    #   :kwarg or :keyword - initializes from a keyword argument with the same name
    #   Example: ivar :@foo, init: :kwarg
    # @param reader [Boolean] If true, creates attr_reader for all declared variables
    #   Example: ivar :@foo, :@bar, reader: true
    # @param writer [Boolean] If true, creates attr_writer for all declared variables
    #   Example: ivar :@foo, :@bar, writer: true
    # @param accessor [Boolean] If true, creates attr_accessor for all declared variables
    #   Example: ivar :@foo, :@bar, accessor: true
    # @param ivar_values [Hash] Individual initial values for instance variables
    #   Example: ivar "@foo": 123, "@bar": 456
    # @yield [varname] Block to generate initial values based on variable name
    #   Example: ivar(:@foo, :@bar) { |varname| "#{varname} default" }
    def ivar(*ivars, value: UNSET, init: nil, reader: false, writer: false, accessor: false, **ivar_values, &block)
      declared = instance_variable_get(:@__ivar_declared_ivars) || []
      initial_values = instance_variable_get(:@__ivar_initial_values) || {}
      init_methods = instance_variable_get(:@__ivar_init_methods) || {}

      new_ivars = ivars.map do |ivar|
        ivar_sym = ivar.to_sym
        ivar_sym.to_s.start_with?("@") ? ivar_sym : :"@#{ivar_sym}"
      end
      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)

      # Handle init method settings
      if init
        new_ivars.each do |ivar_name|
          init_methods[ivar_name] = init
        end
      end

      if block
        new_ivars.each do |ivar_name|
          initial_values[ivar_name] = yield(ivar_name.to_s)
        end
      elsif value != UNSET
        new_ivars.each do |ivar_name|
          initial_values[ivar_name] = value
        end
      end

      ivar_values.each do |ivar_name, val|
        initial_values[ivar_name] = val
        unless declared.include?(ivar_name) || new_ivars.include?(ivar_name)
          new_ivars << ivar_name
        end
      end

      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)
      instance_variable_set(:@__ivar_initial_values, initial_values)
      instance_variable_set(:@__ivar_init_methods, init_methods)

      if reader || writer || accessor
        all_ivars = new_ivars
        attr_names = all_ivars.map { |ivar_name| ivar_name.to_s.delete_prefix("@") }

        attr_reader(*attr_names) if reader || accessor
        attr_writer(*attr_names) if writer || accessor
      end
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      parent_ivars = instance_variable_get(:@__ivar_declared_ivars) || []
      subclass.instance_variable_set(:@__ivar_declared_ivars, parent_ivars.dup)

      parent_values = instance_variable_get(:@__ivar_initial_values) || {}
      subclass.instance_variable_set(:@__ivar_initial_values, parent_values.dup)

      parent_init_methods = instance_variable_get(:@__ivar_init_methods) || {}
      subclass.instance_variable_set(:@__ivar_init_methods, parent_init_methods.dup)
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

    # Get the initialization methods for declared instance variables
    # @return [Hash] Initialization methods for declared instance variables
    def ivar_init_methods
      instance_variable_get(:@__ivar_init_methods) || {}
    end
  end
end
