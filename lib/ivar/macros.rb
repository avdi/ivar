# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # Special flag object to detect when a parameter is not provided
    UNSET = Object.new.freeze

    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
      # For backward compatibility, maintain the old instance variables
      base.instance_variable_set(:@__ivar_declared_ivars, [])
      base.instance_variable_set(:@__ivar_initial_values, {})
      base.instance_variable_set(:@__ivar_init_methods, {})

      # Get or create a manifest for this class
      Ivar.get_manifest(base)
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
      # For backward compatibility, maintain the old instance variables
      declared = instance_variable_get(:@__ivar_declared_ivars) || []
      initial_values = instance_variable_get(:@__ivar_initial_values) || {}
      init_methods = instance_variable_get(:@__ivar_init_methods) || {}

      # Get the manifest for this class
      manifest = Ivar.get_manifest(self)

      # Process the ivars
      new_ivars = ivars.map do |ivar|
        ivar_sym = ivar.to_sym
        ivar_sym.to_s.start_with?("@") ? ivar_sym : :"@#{ivar_sym}"
      end

      # Add to the old-style instance variables for backward compatibility
      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)

      # Create explicit declarations for each ivar
      new_ivars.each do |ivar_name|
        options = {
          init: init,
          value: value,
          reader: reader,
          writer: writer,
          accessor: accessor,
          block: block
        }

        # Create and add the declaration to the manifest
        declaration = ExplicitDeclaration.new(ivar_name, options)
        manifest.add_explicit_declaration(declaration)

        # For backward compatibility, maintain the old instance variables
        init_methods[ivar_name] = init if init

        if block
          initial_values[ivar_name] = yield(ivar_name.to_s)
        elsif value != UNSET
          initial_values[ivar_name] = value
        end
      end

      # Process individual ivar values
      ivar_values.each do |ivar_name, val|
        # Create and add the declaration to the manifest
        options = {
          value: val,
          reader: reader,
          writer: writer,
          accessor: accessor
        }

        declaration = ExplicitDeclaration.new(ivar_name, options)
        manifest.add_explicit_declaration(declaration)

        # For backward compatibility, maintain the old instance variables
        initial_values[ivar_name] = val
        unless declared.include?(ivar_name) || new_ivars.include?(ivar_name)
          new_ivars << ivar_name
        end
      end

      # Update the old-style instance variables for backward compatibility
      instance_variable_set(:@__ivar_declared_ivars, declared + new_ivars)
      instance_variable_set(:@__ivar_initial_values, initial_values)
      instance_variable_set(:@__ivar_init_methods, init_methods)
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
