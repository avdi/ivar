# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/prism_analysis"
require_relative "ivar/policies"
require_relative "ivar/validation"
require_relative "ivar/macros"
require_relative "ivar/project_root"
require_relative "ivar/check_all_manager"
require_relative "ivar/auto_check"
require "prism"
require "did_you_mean"
require "pathname"

module Ivar
  @analysis_cache = {}
  @checked_classes = {}
  @default_check_policy = :warn_once
  MUTEX = Mutex.new
  PROJECT_ROOT_FINDER = ProjectRoot.new
  CHECK_ALL_MANAGER = CheckAllManager.new

  # Returns a cached analysis for the given class or module
  # Creates a new analysis if one doesn't exist in the cache
  # Thread-safe: Multiple readers are allowed, but writers block all other access
  def self.get_analysis(klass)
    # First try a fast read-only check without locking
    return @analysis_cache[klass] if @analysis_cache.key?(klass)

    # If not found, acquire lock and check again (double-checked locking pattern)
    MUTEX.synchronize do
      @analysis_cache[klass] ||= PrismAnalysis.new(klass)
    end
  end

  # Checks if a class has been validated already
  # @param klass [Class] The class to check
  # @return [Boolean] Whether the class has been validated
  # Thread-safe: Read-only operation
  def self.class_checked?(klass)
    MUTEX.synchronize { @checked_classes.key?(klass) }
  end

  # Marks a class as having been checked
  # @param klass [Class] The class to mark as checked
  # Thread-safe: Write operation protected by mutex
  def self.mark_class_checked(klass)
    MUTEX.synchronize { @checked_classes[klass] = true }
  end

  # For testing purposes - allows clearing the cache
  # Thread-safe: Write operation protected by mutex
  def self.clear_analysis_cache
    MUTEX.synchronize do
      @analysis_cache.clear
      @checked_classes.clear
    end
    PROJECT_ROOT_FINDER.clear_cache
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
    MUTEX.synchronize { @default_check_policy = policy }
  end

  # Determines the project root directory based on the caller's location
  # Delegates to ProjectRoot class
  # @param caller_location [String, nil] Optional file path to start from (defaults to caller's location)
  # @return [String] The absolute path to the project root directory
  def self.project_root(caller_location = nil)
    PROJECT_ROOT_FINDER.find(caller_location)
  end

  # Enables automatic inclusion of Ivar::Checked in all classes and modules
  # defined within the project root.
  #
  # @param block [Proc] Optional block. If provided, auto-checking is only active
  #   for the duration of the block. Otherwise, it remains active indefinitely.
  # @return [void]
  def self.check_all(&block)
    # Get the project root to determine which files are in the project
    root = project_root

    # Delegate to the CheckAllManager
    CHECK_ALL_MANAGER.enable(root, &block)
  end

  # Disables automatic inclusion of Ivar::Checked in classes and modules.
  # @return [void]
  def self.disable_check_all
    CHECK_ALL_MANAGER.disable
  end
end
