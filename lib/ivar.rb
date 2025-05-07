# frozen_string_literal: true

require_relative "ivar/version"
require_relative "ivar/policies"
require_relative "ivar/validation"
require_relative "ivar/macros"
require_relative "ivar/project_root"
require_relative "ivar/check_all_manager"
require_relative "ivar/auto_check"
require_relative "ivar/manifest"
require_relative "ivar/targeted_prism_analysis"
require "prism"
require "did_you_mean"
require "pathname"

module Ivar
  @analysis_cache = {}
  @checked_classes = {}
  @default_check_policy = :warn_once
  @manifest_registry = {}
  @project_root = nil
  MUTEX = Mutex.new
  PROJECT_ROOT_FINDER = ProjectRoot.new
  CHECK_ALL_MANAGER = CheckAllManager.new

  # Pattern for internal instance variables
  INTERNAL_IVAR_PREFIX = "@__ivar_"

  # Checks if an instance variable name is an internal variable
  # @param ivar_name [Symbol, String] The instance variable name to check
  # @return [Boolean] Whether the variable is an internal variable
  def self.internal_ivar?(ivar_name)
    ivar_name.to_s.start_with?(INTERNAL_IVAR_PREFIX)
  end

  # Returns a list of known internal instance variables
  # @return [Array<Symbol>] List of known internal instance variables
  def self.known_internal_ivars
    [
      :@__ivar_check_policy,
      :@__ivar_initialized_vars,
      :@__ivar_method_impl_stash,
      :@__ivar_skip_init
    ]
  end

  def self.get_ancestral_analyses(klass)
    klass
      .ancestors.filter_map { |ancestor| maybe_get_analysis(ancestor) }
      .reverse
  end

  def self.maybe_get_analysis(klass)
    if klass.include?(Validation)
      get_analysis(klass)
    end
  end

  # Returns a cached analysis for the given class or module
  # Creates a new analysis if one doesn't exist in the cache
  # Thread-safe: Multiple readers are allowed, but writers block all other access
  def self.get_analysis(klass)
    return @analysis_cache[klass] if @analysis_cache.key?(klass)

    MUTEX.synchronize do
      @analysis_cache[klass] ||= TargetedPrismAnalysis.new(klass)
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
      @manifest_registry.clear
    end
    PROJECT_ROOT_FINDER.clear_cache
  end

  # Get or create a manifest for a class or module
  # @param klass [Class, Module] The class or module to get a manifest for
  # @param create [Boolean] Whether to create a new manifest if one doesn't exist
  # @return [Manifest, nil] The manifest for the class or module, or nil if not found and create_if_missing is false
  def self.get_manifest(klass, create: true)
    return @manifest_registry[klass] if @manifest_registry.key?(klass)
    return nil unless create

    MUTEX.synchronize do
      @manifest_registry[klass] ||= Manifest.new(klass)
    end
  end

  # Check if a manifest exists for a class or module
  # @param klass [Class, Module] The class or module to check
  # @return [Boolean] Whether a manifest exists for the class or module
  def self.manifest_exists?(klass)
    @manifest_registry.key?(klass)
  end

  # Get the default check policy
  # @return [Symbol] The default check policy
  def self.check_policy
    @default_check_policy
  end

  # Set the default check policy
  # @param policy [Symbol, Policy] The default check policy
  def self.check_policy=(policy)
    MUTEX.synchronize { @default_check_policy = policy }
  end

  def self.project_root=(explicit_root)
    @project_root = explicit_root
  end

  # Determines the project root directory based on the caller's location
  # Delegates to ProjectRoot class
  # @param caller_location [String, nil] Optional file path to start from (defaults to caller's location)
  # @return [String] The absolute path to the project root directory
  def self.project_root(caller_location = nil)
    @project_root ||= PROJECT_ROOT_FINDER.find(caller_location)
  end

  # Enables automatic inclusion of Ivar::Checked in all classes and modules
  # defined within the project root.
  #
  # @param block [Proc] Optional block. If provided, auto-checking is only active
  #   for the duration of the block. Otherwise, it remains active indefinitely.
  # @return [void]
  def self.check_all(&block)
    root = project_root
    CHECK_ALL_MANAGER.enable(root, &block)
  end

  # Disables automatic inclusion of Ivar::Checked in classes and modules.
  # @return [void]
  def self.disable_check_all
    CHECK_ALL_MANAGER.disable
  end

  # Gets the method implementation stash for a class
  # @param klass [Class] The class to get the stash for
  # @return [Hash] The method stash (empty hash if none exists)
  def self.get_method_stash(klass)
    klass.instance_variable_get(:@__ivar_method_impl_stash) || {}
  end

  # Gets a method from the stash or returns nil if not found
  # @param klass [Class] The class that owns the method
  # @param method_name [Symbol] The name of the method to retrieve
  # @return [UnboundMethod, nil] The stashed method or nil if not found
  def self.get_stashed_method(klass, method_name)
    stash = get_method_stash(klass)
    stash[method_name]
  end
end
