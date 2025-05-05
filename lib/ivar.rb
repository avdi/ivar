# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/prism_analysis"
require_relative "ivar/policies"
require_relative "ivar/validation"
require_relative "ivar/macros"
require_relative "ivar/auto_check"
require "prism"
require "did_you_mean"
require "pathname"

module Ivar
  @analysis_cache = {}
  @checked_classes = {}
  @default_check_policy = :warn_once
  @mutex = Mutex.new
  @project_root_cache = {}

  # Returns a cached analysis for the given class or module
  # Creates a new analysis if one doesn't exist in the cache
  # Thread-safe: Multiple readers are allowed, but writers block all other access
  def self.get_analysis(klass)
    # First try a fast read-only check without locking
    return @analysis_cache[klass] if @analysis_cache.key?(klass)

    # If not found, acquire lock and check again (double-checked locking pattern)
    @mutex.synchronize do
      @analysis_cache[klass] ||= PrismAnalysis.new(klass)
    end
  end

  # Checks if a class has been validated already
  # @param klass [Class] The class to check
  # @return [Boolean] Whether the class has been validated
  # Thread-safe: Read-only operation
  def self.class_checked?(klass)
    @mutex.synchronize { @checked_classes.key?(klass) }
  end

  # Marks a class as having been checked
  # @param klass [Class] The class to mark as checked
  # Thread-safe: Write operation protected by mutex
  def self.mark_class_checked(klass)
    @mutex.synchronize { @checked_classes[klass] = true }
  end

  # For testing purposes - allows clearing the cache
  # Thread-safe: Write operation protected by mutex
  def self.clear_analysis_cache
    @mutex.synchronize do
      @analysis_cache.clear
      @checked_classes.clear
    end
  end

  # Get the default check policy
  # @return [Symbol] The default check policy
  def self.check_policy
    # No need for synchronization as this is a read-only operation
    # on an immutable value that's only set during initialization or
    # explicitly through check_policy=
    @default_check_policy
  end

  # Set the default check policy
  # @param policy [Symbol, Policy] The default check policy
  def self.check_policy=(policy)
    @mutex.synchronize { @default_check_policy = policy }
  end

  # Determines the project root directory based on the caller's location
  # Walks up the directory tree looking for tell-tale files like Gemfile
  # @param caller_location [String, nil] Optional file path to start from (defaults to caller's location)
  # @return [String] The absolute path to the project root directory
  def self.project_root(caller_location = nil)
    # Get the caller's file path if not provided
    file_path = caller_location || caller_locations(1, 1).first&.path
    return Dir.pwd unless file_path # Fallback to current directory if no path available

    # Check if we've already determined the project root for this file
    @mutex.synchronize do
      return @project_root_cache[file_path] if @project_root_cache.key?(file_path)
    end

    # Convert to absolute path and get the directory
    dir = File.dirname(File.expand_path(file_path))

    # Walk up the directory tree looking for project root indicators
    root = find_project_root(dir)

    # Cache the result for future calls
    @mutex.synchronize do
      @project_root_cache[file_path] = root
    end

    root
  end

  # Project root indicator files, in order of precedence
  PROJECT_ROOT_INDICATORS = %w[Gemfile .git .ruby-version Rakefile].freeze

  # Find the project root by walking up the directory tree
  # @param start_dir [String] Directory to start the search from
  # @return [String] The project root directory
  def self.find_project_root(start_dir)
    path = Pathname.new(start_dir)

    # Use Pathname#ascend to walk up the directory tree
    path.ascend do |dir|
      # Check for each indicator file
      PROJECT_ROOT_INDICATORS.each do |indicator|
        return dir.to_s if dir.join(indicator).exist?
      end
    end

    # If no project root found, return the starting directory
    start_dir
  end

  private_class_method :find_project_root
end
