# frozen_string_literal: true

require "logger"

module Ivar
  # Base class for all ivar checking policies
  class Policy
    # Handle unknown instance variables
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(unknown_refs, klass, allowed_ivars)
      raise NotImplementedError, "Subclasses must implement handle_unknown_ivars"
    end

    # Find the closest match for a variable name
    # @param ivar [Symbol] The variable to find a match for
    # @param known_ivars [Array<Symbol>] List of known variables
    # @return [Symbol, nil] The closest match or nil if none found
    def find_closest_match(ivar, known_ivars)
      finder = DidYouMean::SpellChecker.new(dictionary: known_ivars)
      suggestions = finder.correct(ivar.to_s)
      suggestions.first&.to_sym if suggestions.any?
    end

    # Format a warning message for an unknown instance variable
    # @param ref [Hash] Reference to an unknown instance variable
    # @param suggestion [Symbol, nil] Suggested correction or nil
    # @return [String] Formatted warning message
    def format_warning(ref, suggestion)
      ivar = ref[:name]
      suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""
      "#{ref[:path]}:#{ref[:line]}: warning: unknown instance variable #{ivar}. #{suggestion_text}\n"
    end
  end

  # Policy that warns about unknown instance variables
  class WarnPolicy < Policy
    # Handle unknown instance variables by emitting warnings
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(unknown_refs, _klass, allowed_ivars)
      unknown_refs.each do |ref|
        ivar = ref[:name]
        suggestion = find_closest_match(ivar, allowed_ivars)
        $stderr.write(format_warning(ref, suggestion))
      end
    end
  end

  # Policy that warns about unknown instance variables only once per class
  class WarnOncePolicy < Policy
    # Handle unknown instance variables by emitting warnings once per class
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(unknown_refs, klass, allowed_ivars)
      # Skip if this class has already been checked
      return if Ivar.class_checked?(klass)

      # Emit warnings
      unknown_refs.each do |ref|
        ivar = ref[:name]
        suggestion = find_closest_match(ivar, allowed_ivars)
        $stderr.write(format_warning(ref, suggestion))
      end

      # Mark this class as having been checked
      Ivar.mark_class_checked(klass)
    end
  end

  # Policy that raises an exception for unknown instance variables
  class RaisePolicy < Policy
    # Handle unknown instance variables by raising an exception
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(unknown_refs, _klass, allowed_ivars)
      return if unknown_refs.empty?

      # Get the first unknown reference
      ref = unknown_refs.first
      ivar = ref[:name]
      suggestion = find_closest_match(ivar, allowed_ivars)
      suggestion_text = suggestion ? " Did you mean: #{suggestion}?" : ""

      # Raise an exception with location information
      message = "#{ref[:path]}:#{ref[:line]}: unknown instance variable #{ivar}.#{suggestion_text}"
      raise NameError, message
    end
  end

  # Policy that logs unknown instance variables to a logger
  class LogPolicy < Policy
    # Initialize with a logger
    # @param logger [Logger] The logger to use
    def initialize(logger: Logger.new($stderr))
      @logger = logger
    end

    # Handle unknown instance variables by logging them
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(unknown_refs, _klass, allowed_ivars)
      unknown_refs.each do |ref|
        ivar = ref[:name]
        suggestion = find_closest_match(ivar, allowed_ivars)
        suggestion_text = suggestion ? " Did you mean: #{suggestion}?" : ""
        message = "#{ref[:path]}:#{ref[:line]}: unknown instance variable #{ivar}.#{suggestion_text}"
        @logger.warn(message)
      end
    end
  end

  # Policy that does nothing (no-op) for unknown instance variables
  class NonePolicy < Policy
    # Handle unknown instance variables by doing nothing
    # @param unknown_refs [Array<Hash>] References to unknown instance variables
    # @param klass [Class] The class being checked
    # @param allowed_ivars [Array<Symbol>] List of allowed instance variables
    def handle_unknown_ivars(_unknown_refs, _klass, _allowed_ivars)
      # No-op - do nothing
    end
  end

  # Map of policy symbols to policy classes
  POLICY_CLASSES = {
    warn: WarnPolicy,
    warn_once: WarnOncePolicy,
    raise: RaisePolicy,
    log: LogPolicy,
    none: NonePolicy
  }.freeze

  # Get a policy instance from a symbol or policy object
  # @param policy [Symbol, Policy, Array] The policy to get
  # @param options [Hash] Options to pass to the policy constructor
  # @return [Policy] The policy instance
  def self.get_policy(policy, **options)
    return policy if policy.is_a?(Policy)

    # Handle the case where policy is an array with [policy_name, options]
    if policy.is_a?(Array) && policy.size == 2 && policy[1].is_a?(Hash)
      policy_name, policy_options = policy
      policy_class = POLICY_CLASSES[policy_name]
      raise ArgumentError, "Unknown policy: #{policy_name}" unless policy_class

      return policy_class.new(**policy_options)
    end

    policy_class = POLICY_CLASSES[policy]
    raise ArgumentError, "Unknown policy: #{policy}" unless policy_class

    policy_class.new(**options)
  end
end
