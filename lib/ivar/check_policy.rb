# frozen_string_literal: true

module Ivar
  # Module for adding instance variable check policy configuration to classes.
  # This module provides a way to set and inherit check policies for instance variables.
  # When extended in a class, it allows setting a class-specific policy that overrides
  # the global Ivar policy.
  module CheckPolicy
    # Set or get the check policy for this class
    # @param policy [Symbol, Policy] The check policy to set
    # @param options [Hash] Additional options for the policy
    # @return [Symbol, Policy] The current check policy
    def ivar_check_policy(policy = nil, **options)
      if policy.nil?
        @__ivar_check_policy || Ivar.check_policy
      else
        @__ivar_check_policy = options.empty? ? policy : [policy, options]
      end
    end

    # Ensure subclasses inherit the check policy from their parent
    # This method is called automatically when a class is inherited
    # @param subclass [Class] The subclass that is inheriting from this class
    def inherited(subclass)
      super
      subclass.instance_variable_set(:@__ivar_check_policy, @__ivar_check_policy)
    end
  end
end
