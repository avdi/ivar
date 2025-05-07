# frozen_string_literal: true

require_relative "explicit_declaration"

module Ivar
  # Represents an explicit declaration that initializes from positional arguments
  class ExplicitPositionalDeclaration < ExplicitDeclaration
    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      super
      if args.length > 0
        instance.instance_variable_set(@name, args.shift)
      end
    end
  end
end
