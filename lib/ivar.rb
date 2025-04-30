# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/prism_analysis"
require_relative "ivar/policies"
require_relative "ivar/validation"
require_relative "ivar/macros"
require_relative "ivar/auto_check"
require "prism"
require "did_you_mean"

module Ivar
  @analysis_cache = {}
  @checked_classes = {}
  @default_check_policy = :warn

  # Returns a cached analysis for the given class or module
  # Creates a new analysis if one doesn't exist in the cache
  def self.get_analysis(klass)
    @analysis_cache[klass] ||= PrismAnalysis.new(klass)
  end

  # Checks if a class has been validated already
  # @param klass [Class] The class to check
  # @return [Boolean] Whether the class has been validated
  def self.class_checked?(klass)
    @checked_classes.key?(klass)
  end

  # Marks a class as having been checked
  # @param klass [Class] The class to mark as checked
  def self.mark_class_checked(klass)
    @checked_classes[klass] = true
  end

  # For testing purposes - allows clearing the cache
  def self.clear_analysis_cache
    @analysis_cache.clear
    @checked_classes.clear
  end

  # Get the default check policy
  # @return [Symbol] The default check policy
  def self.check_policy
    @default_check_policy
  end

  # Set the default check policy
  # @param policy [Symbol, Policy] The default check policy
  def self.check_policy=(policy)
    @default_check_policy = policy
  end
end
