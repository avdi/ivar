# frozen_string_literal: true

module Ivar
  # Provides macros for working with instance variables
  module Macros
    # Special flag object to detect when a parameter is not provided
    UNSET = Object.new.freeze

    # When this module is extended, it adds class methods to the extending class
    def self.extended(base)
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
      # Get the manifest for this class
      manifest = Ivar.get_manifest(self)

      # Process the ivars
      new_ivars = ivars.map do |ivar|
        ivar_sym = ivar.to_sym
        ivar_sym.to_s.start_with?("@") ? ivar_sym : :"@#{ivar_sym}"
      end

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
      end
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
    end
  end
end
