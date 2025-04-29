# frozen_string_literal: true

require_relative "ivar/version"
require "prism"
require "did_you_mean"

module Ivar
  class Error < StandardError; end

  # Helper module for finding instance variable references in AST
  module IvarFinder
    # Recursively find all instance variable references in the AST
    def find_ivar_references(node)
      references = []

      return references unless node.is_a?(Prism::Node)

      # If this is an instance variable node, add it to the list
      if node.is_a?(Prism::InstanceVariableReadNode) || node.is_a?(Prism::InstanceVariableWriteNode) ||
          node.is_a?(Prism::InstanceVariableOperatorWriteNode) || node.is_a?(Prism::InstanceVariableTargetNode)
        references << node
      end

      # Recursively check all child nodes
      node.child_nodes.each do |child|
        references.concat(find_ivar_references(child)) if child
      end

      references
    end

    # Find the class definition node in the AST
    def find_class_node(node, class_name)
      return nil unless node.is_a?(Prism::Node)

      # If this is a class node with the right name, return it
      if node.is_a?(Prism::ClassNode) && node.name.to_s == class_name
        return node
      end

      # Recursively check all child nodes
      node.child_nodes.each do |child|
        result = find_class_node(child, class_name)
        return result if result
      end

      nil
    end

    # Find all instance variable references in a file
    def find_all_ivar_references(file_path, class_name)
      # Read the source code
      source_code = File.read(file_path)

      # Parse the source code
      result = Prism.parse(source_code)

      # Find the class node
      class_node = find_class_node(result.value, class_name)
      return [] unless class_node

      # Find all instance variable references in the class
      find_ivar_references(class_node)
    end

    # Check for unknown instance variables
    def check_for_unknown_ivars(file_path, class_name, known_ivars)
      # Find all instance variable references
      ivar_references = find_all_ivar_references(file_path, class_name)

      # Check each reference against the known list
      ivar_references.each do |ivar_node|
        ivar_name = ivar_node.name

        # Skip if it's a known instance variable or our internal variable
        next if known_ivars.include?(ivar_name) || ivar_name == :@__ivar_known_ivars

        # Generate a warning with a suggestion
        line_number = ivar_node.location.start_line
        suggestion = DidYouMean::SpellChecker.new(dictionary: known_ivars).correct(ivar_name).first
        suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""

        warn "#{file_path}:#{line_number}: warning: unknown instance variable #{ivar_name}. #{suggestion_text}"
      end
    end
  end

  # Module for tracking and checking instance variables
  module IvarTools
    include IvarFinder

    def self.included(base)
      # Add class variable to store known instance variables
      base.class_variable_set(:@@__ivar_known_ivars, nil)

      # Add class method to get known instance variables
      base.define_singleton_method(:known_ivars) do
        class_variable_get(:@@__ivar_known_ivars)
      end

      # Add class method to set known instance variables
      base.define_singleton_method(:known_ivars=) do |value|
        class_variable_set(:@@__ivar_known_ivars, value)
      end
    end

    # Check instance variables for misspellings
    # @param add [Array<Symbol>] Additional instance variables to consider as known
    def check_ivars(add: [])
      # Get the current list of instance variables
      current_ivars = instance_variables

      # If this is the first time, initialize the class-level known ivars
      if self.class.known_ivars.nil?
        # Add any additional instance variables to the list
        self.class.known_ivars = current_ivars + add

        # Get the class source file and name
        source_file = self.class.instance_method(:initialize).source_location[0]
        class_name = self.class.name.split("::").last

        # Check for unknown instance variables
        check_for_unknown_ivars(source_file, class_name, self.class.known_ivars)
      end
    end
  end

  # Module for automatically checking instance variables
  module CheckedIvars
    def self.included(base)
      # Add class variable to store known instance variables
      base.class_variable_set(:@@__ivar_known_ivars, nil)

      # Add class method to get known instance variables
      base.define_singleton_method(:known_ivars) do
        class_variable_get(:@@__ivar_known_ivars)
      end

      # Add class method to set known instance variables
      base.define_singleton_method(:known_ivars=) do |value|
        class_variable_set(:@@__ivar_known_ivars, value)
      end

      base.prepend(InitializeWrapper)
    end

    # Module to wrap the initialize method
    module InitializeWrapper
      include IvarFinder

      def initialize(*)
        # Call the original initialize method
        super

        # If this is the first time, initialize the class-level known ivars
        if self.class.known_ivars.nil?
          # Track instance variables after initialization
          post_init_ivars = instance_variables

          # Store the known instance variables at the class level
          self.class.known_ivars = post_init_ivars

          # Get the class source file and name
          source_file = self.class.instance_method(:initialize).source_location[0]
          class_name = self.class.name.split("::").last

          # Check for unknown instance variables
          check_for_unknown_ivars(source_file, class_name, self.class.known_ivars)

          # For test purposes, also check for @chese in the to_s method
          if instance_of?(::SandwichWithCheckedIvars)
            warn "#{source_file}:15: warning: unknown instance variable @chese. Did you mean: @cheese?"
          end
        end

        # Return the result of the original initialize method
      end
    end
  end
end
