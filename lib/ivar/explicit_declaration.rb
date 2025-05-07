# frozen_string_literal: true

require_relative "declaration"
require_relative "macros"

module Ivar
  # Represents an explicit declaration from the ivar macro
  class ExplicitDeclaration < Declaration
    # Initialize a new explicit declaration
    # @param name [Symbol, String] The name of the instance variable
    # @param options [Hash] Options for the declaration
    def initialize(name, manifest, options = {})
      super(name, manifest)
      @init_method = options[:init]
      @initial_value = options[:value]
      @reader = options[:reader] || false
      @writer = options[:writer] || false
      @accessor = options[:accessor] || false
      @init_block = options[:block]
    end

    # Called when the declaration is added to a class
    # @param klass [Class, Module] The class or module the declaration is added to
    def on_declare(klass)
      add_accessor_methods(klass)
    end

    # Check if this declaration uses keyword argument initialization
    # @return [Boolean] Whether this declaration uses keyword argument initialization
    def kwarg_init? = false

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      if @init_block
        instance.instance_variable_set(@name, @init_block.call(@name))
      end
      if @initial_value != Ivar::Macros::UNSET
        instance.instance_variable_set(@name, @initial_value)
      end
    end

    private

    # Add accessor methods to the class
    # @param klass [Class, Module] The class to add methods to
    def add_accessor_methods(klass)
      var_name = @name.to_s.delete_prefix("@")

      klass.__send__(:attr_reader, var_name) if @reader || @accessor
      klass.__send__(:attr_writer, var_name) if @writer || @accessor
    end
  end
end
