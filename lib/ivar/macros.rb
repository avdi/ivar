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
    # @param ivars_with_values [Hash] Individual initial values for instance variables
    #   Example: ivar "@foo": 123, "@bar": 456
    # @yield [varname] Block to generate initial values based on variable name
    #   Example: ivar(:@foo, :@bar) { |varname| "#{varname} default" }
    def ivar(*ivars, value: UNSET, init: nil, reader: false, writer: false, accessor: false, **ivars_with_values, &block)
      manifest = Ivar.get_manifest(self)

      ivar_hash = ivars.map { |ivar| [ivar, value] }.to_h.merge(ivars_with_values)

      ivar_hash.each do |ivar_name, ivar_value|
        raise ArgumentError, "ivars must be symbols (#{ivar_name.inspect})" unless ivar_name.is_a?(Symbol)
        raise ArgumentError, "ivar names must start with @ (#{ivar_name.inspect})" unless /\A@/.match?(ivar_name)

        options = {init:, value: ivar_value, reader:, writer:, accessor:, block:}

        declaration = ExplicitDeclaration.new(ivar_name, manifest, options)
        manifest.add_explicit_declaration(declaration)
      end
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
    end
  end
end
