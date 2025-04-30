# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/prism_analysis"
require_relative "ivar/validation"
require_relative "ivar/checked"
require "prism"
require "did_you_mean"

module Ivar
  @analysis_cache = {}
  @checked_classes = {}

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
end
