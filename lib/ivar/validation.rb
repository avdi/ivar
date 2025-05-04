# frozen_string_literal: true

require "did_you_mean"

module Ivar
  # Provides validation for instance variables
  module Validation
    # Checks instance variables against class analysis
    # @param add [Array<Symbol>] Additional instance variables to allow
    # @param policy [Symbol, Policy] The policy to use for handling unknown variables
    def check_ivars(add: [], policy: nil)
      # Get the policy to use
      policy ||= get_check_policy

      # Get the class analysis from the cache
      analysis = Ivar.get_analysis(self.class)

      # Get all instance variables defined in the current object
      # These are the ones the user has explicitly defined before calling check_ivars
      defined_ivars = instance_variables.map(&:to_sym)

      # Get all declared instance variables from the class hierarchy
      declared_ivars = collect_declared_ivars

      # Add any additional allowed variables
      allowed_ivars = defined_ivars + declared_ivars + add

      # Get all instance variable references from the analysis
      # This includes location information for each reference
      references = analysis.ivar_references

      # Add internal instance variables to the allowed list
      internal_ivars = [:@__ivar_check_policy, :@__ivar_declared_ivars, :@__ivar_initial_values]
      allowed_ivars += internal_ivars

      # Get class-level instance variables (defined on the class itself)
      class_level_ivars = self.class.instance_variables.map(&:to_sym)

      # Add class-level instance variables to the allowed list
      allowed_ivars += class_level_ivars

      # Find references to unknown variables (those not in allowed_ivars)
      unknown_refs = references.reject { |ref| allowed_ivars.include?(ref[:name]) }

      # Handle unknown variables according to the policy
      policy_instance = Ivar.get_policy(policy)
      policy_instance.handle_unknown_ivars(unknown_refs, self.class, allowed_ivars)
    end

    private

    # Get the check policy for this instance
    # @return [Symbol, Policy] The check policy
    def get_check_policy
      # If the class has an ivar_check_policy method, use that
      return self.class.ivar_check_policy if self.class.respond_to?(:ivar_check_policy)

      # Otherwise, use the global default
      Ivar.check_policy
    end

    # Collect all declared instance variables from the class hierarchy
    # @return [Array<Symbol>] All declared instance variables
    def collect_declared_ivars
      klass = self.class
      declared_ivars = []

      # Walk up the inheritance chain
      while klass
        # If the class responds to ivar_declared, add its declared ivars
        if klass.respond_to?(:ivar_declared)
          declared_ivars.concat(klass.ivar_declared)
        end

        # Move up to the superclass
        klass = klass.superclass
      end

      declared_ivars.uniq
    end
  end
end
