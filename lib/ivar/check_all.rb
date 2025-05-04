# frozen_string_literal: true

module Ivar
  @checked_modules = {}
  @check_all_mutex = Mutex.new

  # Applies Ivar::Checked to all modules and classes defined in the project.
  # This method should be invoked at the end of loading files for a project.
  # It uses ObjectSpace to find all modules and classes defined in the project
  # and includes Ivar::Checked into them.
  #
  # @return [Integer] The number of classes/modules that were modified
  def self.check_all
    # Get the caller's file path to determine the project root
    caller_path = caller_locations(1, 1).first.path
    project_root = File.dirname(File.absolute_path(caller_path))

    # Find and modify all modules/classes in the project
    count = 0

    # We need to collect modules first to avoid modifying while iterating
    modules_to_check = []

    ObjectSpace.each_object(Module) do |mod|
      # Skip if already processed
      next if @checked_modules[mod]

      # Skip if it already includes Ivar::Validation
      next if mod.included_modules.include?(Ivar::Validation)

      # Skip core classes and modules
      next if core_module?(mod)

      # Find the source location of the module
      source_location = find_module_source_location(mod)

      # Skip if no source location found
      next unless source_location

      # Check if the file is in the project
      next unless project_file?(source_location, project_root)

      modules_to_check << mod
    end

    # Now apply Ivar::Checked to the collected modules
    modules_to_check.each do |mod|
      # Skip if it already includes Ivar::Validation (double-check)
      next if mod.included_modules.include?(Ivar::Validation)

      begin
        mod.include(Ivar::Checked)
        @checked_modules[mod] = true
        count += 1
      rescue => _e
        # Some modules might not allow including modules (e.g., BasicObject)
        # Just skip them and continue
        next
      end
    end

    count
  end

  # Determines if a module is a core Ruby module that should be skipped
  #
  # @param mod [Module] The module to check
  # @return [Boolean] Whether the module is a core module
  def self.core_module?(mod)
    # Skip modules in these namespaces
    return true if mod.name&.start_with?("Kernel", "BasicObject", "Object", "Module", "Class")
    return true if mod.name&.start_with?("Gem", "Bundler", "RubyVM", "Minitest")

    # Skip anonymous modules created by the system
    return true if mod.name.nil? && !find_module_source_location(mod)

    false
  end

  # Finds the source location of a module by checking its instance methods
  #
  # @param mod [Module] The module to find the source location for
  # @return [String, nil] The source file path or nil if not found
  def self.find_module_source_location(mod)
    # Try to find the source location from instance methods
    mod.instance_methods(false).each do |method_name|
      method_obj = mod.instance_method(method_name)
      location = method_obj.source_location
      return location[0] if location
    rescue => _e
      # Some methods might not have source locations or might raise errors
      next
    end

    # Try to find the source location from singleton methods
    (mod.singleton_methods(false) - Module.singleton_methods).each do |method_name|
      method_obj = mod.method(method_name)
      location = method_obj.source_location
      return location[0] if location
    rescue => _e
      # Some methods might not have source locations or might raise errors
      next
    end

    # If no methods with source locations found, try the constants
    mod.constants(false).each do |const_name|
      const_value = mod.const_get(const_name)
      if const_value.is_a?(Module) && const_value != mod
        location = find_module_source_location(const_value)
        return location if location
      end
    rescue => _e
      # Some constants might raise errors when accessed
      next
    end

    nil
  end

  # Determines if a file is a project file based on the project root
  #
  # @param path [String] The path to check
  # @param project_root [String] The root directory of the project
  # @return [Boolean] Whether the file is a project file
  def self.project_file?(path, project_root)
    return false unless path && !path.empty? && path != "(eval)"

    # Skip standard library, gems, and bundler
    return false if path.include?("/lib/ruby/")
    return false if path.include?("/gems/")
    return false if path.include?("/bundler/")

    # Check if the file is within the project root directory
    path.start_with?(project_root)
  end

  # Clears the list of checked modules
  #
  # @return [Integer] The number of modules that were cleared
  def self.clear_checked_modules
    @check_all_mutex.synchronize do
      count = @checked_modules.size
      @checked_modules.clear
      count
    end
  end
end
