# frozen_string_literal: true

module Ivar
  # Provides a clean interface for storing and retrieving original method implementations
  # This is used when methods are overridden (e.g., by prepend) but we still need
  # access to the original implementation for analysis purposes
  module MethodStash
    # Stores the original implementation of a method in a class's method stash
    # @param klass [Class] The class that owns the method
    # @param method_name [Symbol] The name of the method to stash
    # @return [UnboundMethod, nil] The stashed method or nil if the method doesn't exist
    def self.store_method(klass, method_name)
      return nil unless klass.method_defined?(method_name) || klass.private_method_defined?(method_name)

      method_impl = klass.instance_method(method_name)
      stash = get_or_create_stash(klass)
      stash[method_name] = method_impl
      method_impl
    end

    # Stores multiple method implementations in a class's method stash
    # @param klass [Class] The class that owns the methods
    # @param method_names [Array<Symbol>] The names of the methods to stash
    # @return [Hash] A hash mapping method names to their stashed implementations
    def self.store_methods(klass, method_names)
      method_names.each_with_object({}) do |method_name, result|
        result[method_name] = store_method(klass, method_name)
      end
    end

    # Retrieves a stashed method implementation
    # @param klass [Class] The class that owns the method
    # @param method_name [Symbol] The name of the method to retrieve
    # @return [UnboundMethod, nil] The stashed method or nil if not found
    def self.retrieve_method(klass, method_name)
      stash = get_stash(klass)
      stash&.[](method_name)
    end

    # Checks if a method is stashed for a class
    # @param klass [Class] The class to check
    # @param method_name [Symbol] The name of the method to check
    # @return [Boolean] Whether the method is stashed
    def self.method_stashed?(klass, method_name)
      stash = get_stash(klass)
      stash&.key?(method_name) || false
    end

    # Returns all stashed methods for a class
    # @param klass [Class] The class to get stashed methods for
    # @return [Hash] A hash mapping method names to their stashed implementations
    def self.all_stashed_methods(klass)
      stash = get_stash(klass)
      stash || {}
    end

    # Clears the method stash for a class
    # @param klass [Class] The class to clear the stash for
    # @return [Hash, nil] The previous stash or nil if none existed
    def self.clear_stash(klass)
      klass.instance_variable_get(:@__ivar_method_impl_stash).tap do
        klass.instance_variable_set(:@__ivar_method_impl_stash, {})
      end
    end

    # Gets the method stash for a class
    # @param klass [Class] The class to get the stash for
    # @return [Hash, nil] The method stash or nil if none exists
    def self.get_stash(klass)
      klass.instance_variable_get(:@__ivar_method_impl_stash)
    end

    # Gets or creates the method stash for a class
    # @param klass [Class] The class to get or create the stash for
    # @return [Hash] The method stash
    def self.get_or_create_stash(klass)
      klass.instance_variable_get(:@__ivar_method_impl_stash) ||
        klass.instance_variable_set(:@__ivar_method_impl_stash, {})
    end

    private_class_method :get_stash, :get_or_create_stash
  end
end
