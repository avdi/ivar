# frozen_string_literal: true

require "pathname"

module Ivar
  # Handles project root detection and caching
  class ProjectRoot
    # Project root indicator files, in order of precedence
    INDICATORS = %w[Gemfile .git .ruby-version Rakefile].freeze

    def initialize
      @cache = {}
      @mutex = Mutex.new
    end

    # Determines the project root directory based on the caller's location
    # @param caller_location [String, nil] Optional file path to start from (defaults to caller's location)
    # @return [String] The absolute path to the project root directory
    def find(caller_location = nil)
      # Get the caller's file path if not provided
      file_path = caller_location || caller_locations(2, 1).first&.path
      return Dir.pwd unless file_path # Fallback to current directory if no path available

      # Check if we've already determined the project root for this file
      @mutex.synchronize do
        return @cache[file_path] if @cache.key?(file_path)
      end

      # Convert to absolute path and get the directory
      dir = File.dirname(File.expand_path(file_path))

      # Walk up the directory tree looking for project root indicators
      root = find_project_root(dir)

      # Cache the result for future calls
      @mutex.synchronize do
        @cache[file_path] = root
      end

      root
    end

    # Clear the cache (mainly for testing)
    def clear_cache
      @mutex.synchronize { @cache.clear }
    end

    private

    # Find the project root by walking up the directory tree
    # @param start_dir [String] Directory to start the search from
    # @return [String] The project root directory
    def find_project_root(start_dir)
      path = Pathname.new(start_dir)

      # Use Pathname#ascend to walk up the directory tree
      path.ascend do |dir|
        # Check for each indicator file
        INDICATORS.each do |indicator|
          return dir.to_s if dir.join(indicator).exist?
        end
      end

      # If no project root found, return the starting directory
      start_dir
    end
  end
end