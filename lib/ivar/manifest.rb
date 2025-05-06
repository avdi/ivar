# frozen_string_literal: true

module Ivar
  # Represents a manifest of instance variable declarations for a class/module
  class Manifest
    # @return [Class, Module] The class or module this manifest is associated with
    attr_reader :owner

    # Initialize a new manifest
    # @param owner [Class, Module] The class or module this manifest is associated with
    def initialize(owner)
      @owner = owner
      @declarations_by_name = {}
    end

    # @return [Hash<Symbol, Declaration>] The declarations hash keyed by variable name
    attr_reader :declarations_by_name

    # @return [Array<Declaration>] The declarations in this manifest
    def declarations
      @declarations_by_name.values
    end

    # Add an explicit declaration to the manifest
    # @param declaration [ExplicitDeclaration] The declaration to add
    # @return [ExplicitDeclaration] The added declaration
    def add_explicit_declaration(declaration)
      name = declaration.name
      @declarations_by_name[name] = declaration
      declaration.on_declare(@owner)
      declaration
    end

    # Add implicit declarations for instance variables that aren't explicitly declared
    # This method is called after object initialization to register any instance variables
    # that were created during initialization but weren't explicitly declared with the ivar macro.
    #
    # @param ivars [Array<Symbol>] List of instance variable names (typically from instance_variables)
    # @return [Array<ImplicitDeclaration>] The added implicit declarations
    def add_implicits(ivars)
      added_declarations = []
      # Filter out variables that are already explicitly declared
      (ivars - explicitly_declared_ivars).each do |ivar|
        declaration = ImplicitDeclaration.new(ivar, self)
        added_declarations << add_implicit_declaration(declaration)
      end
      added_declarations
    end

    # Add an implicit declaration to the manifest
    # @param declaration [ImplicitDeclaration] The declaration to add
    # @return [Declaration] The existing or added declaration
    def add_implicit_declaration(declaration)
      name = declaration.name
      @declarations_by_name[name] ||= declaration
    end

    # Get all ancestor manifests in reverse order (from highest to lowest in the hierarchy)
    # Only includes ancestors that have existing manifests
    # @return [Array<Manifest>] Array of ancestor manifests
    def ancestor_manifests
      return [] unless @owner.respond_to?(:ancestors)

      # Get all ancestors except the owner itself
      ancestors = @owner.ancestors.reject { |ancestor| ancestor == @owner }

      # Filter and map ancestors to manifests, only including those that already have manifests
      # This avoids creating unnecessary manifests for classes/modules that don't declare anything
      ancestors.filter_map { |ancestor| Ivar.get_manifest(ancestor, create: false) }
    end

    def explicitly_declared_ivars
      all_declarations.grep(ExplicitDeclaration).map(&:name)
    end

    # Get all declarations, including those from ancestor manifests
    # @return [Array<Declaration>] All declarations
    def all_declarations
      ancestor_manifests
        .flat_map(&:declarations)
        .+(declarations)
        .reduce({}) { |acc, decl| acc.merge(decl.name => decl) }
        .values
    end

    # Check if a variable is declared in this manifest or ancestor manifests
    # @param name [Symbol, String] The variable name
    # @return [Boolean] Whether the variable is declared
    def declared?(name)
      name = name.to_sym

      # Check in this manifest first
      return true if @declarations_by_name.key?(name)

      # Then check in ancestor manifests
      ancestor_manifests.any? do |ancestor_manifest|
        ancestor_manifest.declarations_by_name.key?(name)
      end
    end

    # Get a declaration by name
    # @param name [Symbol, String] The variable name
    # @return [Declaration, nil] The declaration, or nil if not found
    def get_declaration(name)
      name = name.to_sym

      # Check in this manifest first
      return @declarations_by_name[name] if @declarations_by_name.key?(name)

      # Then check in ancestor manifests, starting from the closest ancestor
      ancestor_manifests.each do |ancestor_manifest|
        if ancestor_manifest.declarations_by_name.key?(name)
          return ancestor_manifest.declarations_by_name[name]
        end
      end

      nil
    end

    # Get all explicit declarations
    # @return [Array<ExplicitDeclaration>] All explicit declarations
    def explicit_declarations
      declarations.select { |decl| decl.is_a?(ExplicitDeclaration) }
    end

    # Get all implicit declarations
    # @return [Array<ImplicitDeclaration>] All implicit declarations
    def implicit_declarations
      declarations.select { |decl| decl.is_a?(ImplicitDeclaration) }
    end

    # Process before_init callbacks for all declarations
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    # @return [Array, Hash] The modified args and kwargs
    def process_before_init(instance, args, kwargs)
      # Get all declarations from parent to child, with child declarations taking precedence
      declarations_to_process = all_declarations

      # Process all initializations in a single pass
      # The before_init method will handle keyword arguments with proper precedence
      declarations_to_process.each do |declaration|
        declaration.before_init(instance, args, kwargs)
      end

      [args, kwargs]
    end
  end

  # Base class for all declarations
  class Declaration
    # @return [Symbol] The name of the instance variable
    attr_reader :name, :manifest

    # Initialize a new declaration
    # @param name [Symbol, String] The name of the instance variable
    def initialize(name, manifest)
      @name = name.to_sym
      @manifest = manifest
    end

    # Called when the declaration is added to a class
    # @param klass [Class, Module] The class or module the declaration is added to
    def on_declare(klass)
      # Base implementation does nothing
    end

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      # Base implementation does nothing
    end
  end

  # Represents an explicit declaration from the ivar macro
  class ExplicitDeclaration < Declaration
    # Initialize a new explicit declaration
    # @param name [Symbol, String] The name of the instance variable
    # @param options [Hash] Options for the declaration
    def initialize(name, manifest, options = {})
      super(name, manifest)
      @init_method = options[:init]
      @initial_value = options[:value]
      @reader = options[:reader] || false
      @writer = options[:writer] || false
      @accessor = options[:accessor] || false
      @init_block = options[:block]
    end

    # Called when the declaration is added to a class
    # @param klass [Class, Module] The class or module the declaration is added to
    def on_declare(klass)
      add_accessor_methods(klass)
    end

    # Check if this declaration uses keyword argument initialization
    # @return [Boolean] Whether this declaration uses keyword argument initialization
    def kwarg_init?
      @init_method && [:kwarg, :keyword].include?(@init_method)
    end

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      if @init_block
        instance.instance_variable_set(@name, @init_block.call(@name))
      end
      if @initial_value != Ivar::Macros::UNSET
        instance.instance_variable_set(@name, @initial_value)
      end
      kwarg_name = @name.to_s.delete_prefix("@").to_sym
      if kwarg_init? && kwargs.key?(kwarg_name)
        instance.instance_variable_set(@name, kwargs.delete(kwarg_name))
      end
    end

    private

    # Add accessor methods to the class
    # @param klass [Class, Module] The class to add methods to
    def add_accessor_methods(klass)
      var_name = @name.to_s.delete_prefix("@")

      klass.__send__(:attr_reader, var_name) if @reader || @accessor
      klass.__send__(:attr_writer, var_name) if @writer || @accessor
    end
  end

  # Represents an implicit declaration from instance variable detection
  class ImplicitDeclaration < Declaration
  end
end
