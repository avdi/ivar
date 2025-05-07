# frozen_string_literal: true

module Ivar
  # Base class for all declarations
  class Declaration
    # @return [Symbol] The name of the instance variable
    attr_reader :name, :manifest

    # Initialize a new declaration
    # @param name [Symbol, String] The name of the instance variable
    def initialize(name, manifest)
      @name = name.to_sym
      @manifest = manifest
    end

    # Called when the declaration is added to a class
    # @param klass [Class, Module] The class or module the declaration is added to
    def on_declare(klass)
      # Base implementation does nothing
    end

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      # Base implementation does nothing
    end
  end
end
