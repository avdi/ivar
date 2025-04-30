# frozen_string_literal: true

require "did_you_mean"

module Ivar
  # Provides validation for instance variables
  module Validation
    # Checks instance variables against class analysis
    # @param add [Array<Symbol>] Additional instance variables to allow
    def check_ivars(add: [])
      # Get the class analysis from the cache
      analysis = Ivar.get_analysis(self.class)

      # Get all instance variables defined in the current object
      # These are the ones the user has explicitly defined before calling check_ivars
      defined_ivars = instance_variables.map(&:to_sym)

      # Add any additional allowed variables
      allowed_ivars = defined_ivars + add

      # Get all instance variable references from the analysis
      # This includes location information for each reference
      references = analysis.ivar_references

      # Find references to unknown variables (those not in allowed_ivars)
      unknown_refs = references.reject { |ref| allowed_ivars.include?(ref[:name]) }

      # Emit warnings for unknown variables - one for each reference location
      unknown_refs.each do |ref|
        ivar = ref[:name]

        # Find the closest match for a suggestion
        suggestion = find_closest_match(ivar, allowed_ivars)
        suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""

        # Emit the warning using the actual location from the reference
        message = "#{ref[:path]}:#{ref[:line]}: warning: unknown instance variable #{ivar}. #{suggestion_text}\n"
        $stderr.write(message)
      end
    end

    private

    # Find the closest match for a variable name
    # @param ivar [Symbol] The variable to find a match for
    # @param known_ivars [Array<Symbol>] List of known variables
    # @return [Symbol, nil] The closest match or nil if none found
    def find_closest_match(ivar, known_ivars)
      finder = DidYouMean::SpellChecker.new(dictionary: known_ivars)
      suggestions = finder.correct(ivar.to_s)
      suggestions.first&.to_sym if suggestions.any?
    end
  end
end
