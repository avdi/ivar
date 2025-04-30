# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/prism_analysis"
require "prism"
require "did_you_mean"

module Ivar
  @analysis_cache = {}

  class << self
    # Returns a cached analysis for the given class or module
    # Creates a new analysis if one doesn't exist in the cache
    def get_analysis(klass)
      @analysis_cache[klass] ||= PrismAnalysis.new(klass)
    end

    # For testing purposes - allows clearing the cache
    def clear_analysis_cache
      @analysis_cache.clear
    end
  end
end
