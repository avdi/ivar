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

      # First, process keyword argument initializations
      # This ensures that keyword arguments take precedence over initial values
      declarations_to_process.each do |declaration|
        if declaration.is_a?(ExplicitDeclaration) && declaration.kwarg_init?
          declaration.initialize_from_kwarg(instance, kwargs)
        end
      end

      # Then, process all other initializations
      declarations_to_process.each do |declaration|
        # Skip keyword initializations that were already processed
        next if declaration.is_a?(ExplicitDeclaration) && declaration.kwarg_init?
        declaration.before_init(instance, args, kwargs)
      end

      [args, kwargs]
    end
  end

  # Base class for all declarations
  class Declaration
    # @return [Symbol] The name of the instance variable
    attr_reader :name

    # Initialize a new declaration
    # @param name [Symbol, String] The name of the instance variable
    def initialize(name)
      @name = name.to_sym
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
    def initialize(name, options = {})
      super(name)
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
      # Add accessor methods if requested
      add_accessor_methods(klass) if @reader || @writer || @accessor
    end

    # Check if this declaration uses keyword argument initialization
    # @return [Boolean] Whether this declaration uses keyword argument initialization
    def kwarg_init?
      @init_method && [:kwarg, :keyword].include?(@init_method)
    end

    # Initialize from keyword argument
    # @param instance [Object] The object being initialized
    # @param kwargs [Hash] Keyword arguments
    def initialize_from_kwarg(instance, kwargs)
      kwarg_name = @name.to_s.delete_prefix("@").to_sym
      if kwargs.key?(kwarg_name)
        # Initialize from keyword argument
        instance.instance_variable_set(@name, kwargs[kwarg_name])
        kwargs.delete(kwarg_name)
      elsif @initial_value != Ivar::Macros::UNSET
        # Fall back to initial value if keyword not provided
        instance.instance_variable_set(@name, @initial_value)
      elsif @init_block
        # Fall back to block if keyword not provided and initial value not set
        value = @init_block.call(@name)
        instance.instance_variable_set(@name, value)
      end
    end

    # Called before object initialization
    # @param instance [Object] The object being initialized
    # @param args [Array] Positional arguments
    # @param kwargs [Hash] Keyword arguments
    def before_init(instance, args, kwargs)
      # Initialize from keyword argument if requested
      if kwarg_init?
        # Keyword initialization is handled in initialize_from_kwarg
        # which is called separately by the manifest
        nil
      # Initialize from initial value if provided
      elsif @initial_value != Ivar::Macros::UNSET
        instance.instance_variable_set(@name, @initial_value)
      # Initialize from block if provided
      elsif @init_block
        value = @init_block.call(@name)
        instance.instance_variable_set(@name, value)
      end
    end

    private

    # Add accessor methods to the class
    # @param klass [Class, Module] The class to add methods to
    def add_accessor_methods(klass)
      var_name = @name.to_s.delete_prefix("@")

      # Add reader method
      if @reader || @accessor
        klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{var_name}
            #{@name}
          end
        RUBY
      end

      # Add writer method
      if @writer || @accessor
        klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{var_name}=(value)
            #{@name} = value
          end
        RUBY
      end
    end
  end

  # Represents an implicit declaration from instance variable detection
  class ImplicitDeclaration < Declaration
    # Initialize a new implicit declaration
    # @param name [Symbol, String] The name of the instance variable
    def initialize(name)
      super
    end
  end
end
