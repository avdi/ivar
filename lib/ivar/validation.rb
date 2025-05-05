# frozen_string_literal: true

require "did_you_mean"

module Ivar
  # Provides validation for instance variables
  module Validation
    # Checks instance variables against class analysis
    # @param add [Array<Symbol>] Additional instance variables to allow
    # @param policy [Symbol, Policy] The policy to use for handling unknown variables
    def check_ivars(add: [], policy: nil)
      policy ||= get_check_policy
      analysis = Ivar.get_analysis(self.class)
      defined_ivars = instance_variables.map(&:to_sym)
      declared_ivars = collect_declared_ivars
      allowed_ivars = defined_ivars + declared_ivars + add
      references = analysis.ivar_references

      internal_ivars = [:@__ivar_check_policy, :@__ivar_declared_ivars, :@__ivar_initial_values]
      allowed_ivars += internal_ivars

      instance_refs = references.reject do |ref|
        ref[:context] == :class || internal_ivars.include?(ref[:name])
      end

      unknown_refs = instance_refs.reject { |ref| allowed_ivars.include?(ref[:name]) }
      policy_instance = Ivar.get_policy(policy)
      policy_instance.handle_unknown_ivars(unknown_refs, self.class, allowed_ivars)
    end

    private

    # Get the check policy for this instance
    # @return [Symbol, Policy] The check policy
    def get_check_policy
      return self.class.ivar_check_policy if self.class.respond_to?(:ivar_check_policy)
      Ivar.check_policy
    end

    # Collect all declared instance variables from the class hierarchy
    # @return [Array<Symbol>] All declared instance variables
    def collect_declared_ivars
      klass = self.class
      declared_ivars = []

      while klass
        if klass.respond_to?(:ivar_declared)
          declared_ivars.concat(klass.ivar_declared)
        end
        klass = klass.superclass
      end

      declared_ivars.uniq
    end
  end
end
