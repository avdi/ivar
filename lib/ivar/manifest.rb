# frozen_string_literal: true

require_relative "declaration"
require_relative "explicit_declaration"
require_relative "explicit_keyword_declaration"
require_relative "explicit_positional_declaration"

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

    # Get all ancestor manifests in reverse order (from highest to lowest in the hierarchy)
    # Only includes ancestors that have existing manifests
    # @return [Array<Manifest>] Array of ancestor manifests
    def ancestor_manifests
      return [] unless @owner.respond_to?(:ancestors)

      @owner
        .ancestors.reject { |ancestor| ancestor == @owner }
        .filter_map { |ancestor| Ivar.get_manifest(ancestor, create: false) }
        .reverse
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
        # use hash stores to preserve order and deduplicate by name
        .each_with_object({}) { |decl, acc| acc[decl.name] = decl }
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
end
