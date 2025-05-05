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
      file_path = caller_location || caller_locations(2, 1).first&.path
      return Dir.pwd unless file_path

      @mutex.synchronize do
        return @cache[file_path] if @cache.key?(file_path)
      end

      dir = File.dirname(File.expand_path(file_path))
      root = find_project_root(dir)

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

      path.ascend do |dir|
        INDICATORS.each do |indicator|
          return dir.to_s if dir.join(indicator).exist?
        end
      end

      start_dir
    end
  end
end
