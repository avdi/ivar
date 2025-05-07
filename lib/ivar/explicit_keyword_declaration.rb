# frozen_string_literal: true

require_relative "explicit_declaration"

module Ivar
  # Represents an explicit declaration that initializes from keyword arguments
  class ExplicitKeywordDeclaration < ExplicitDeclaration
    # Check if this declaration uses keyword argument initialization
    # @return [Boolean] Whether this declaration uses keyword argument initialization
    def kwarg_init? = true

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      super
      kwarg_name = @name.to_s.delete_prefix("@").to_sym
      if kwargs.key?(kwarg_name)
        instance.instance_variable_set(@name, kwargs.delete(kwarg_name))
      end
    end
  end
end
