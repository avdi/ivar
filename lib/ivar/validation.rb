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
      manifest = Ivar.get_manifest(self.class)
      declared_ivars = manifest.all_declarations.map(&:name)
      allowed_ivars = (Ivar.known_internal_ivars | instance_variables | declared_ivars | add).uniq
      instance_refs = analysis.references
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
  end
end
