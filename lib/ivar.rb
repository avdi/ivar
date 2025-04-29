# frozen_string_literal: true

require_relative "ivar/version"
require "prism"
require "did_you_mean"

module Ivar
  class Error < StandardError; end

  # Module for tracking and checking instance variables
  module IvarTools
    # Check instance variables for misspellings
    # @param add [Array<Symbol>] Additional instance variables to consider as known
    def check_ivars(add: [])
      # Get the current list of instance variables
      current_ivars = instance_variables

      # Add any additional instance variables to the list
      @__ivar_known_ivars = current_ivars + add

      # Parse the class definition to find all instance variable references
      audit_class_for_unknown_ivars
    end

    private

    # Use Prism to parse the class definition and find all instance variable references
    def audit_class_for_unknown_ivars
      # Get the class source file
      source_file = self.class.instance_method(:initialize).source_location[0]
      source_code = File.read(source_file)

      # Parse the source code
      result = Prism.parse(source_code)

      # Find all instance variable references
      ivar_references = find_ivar_references(result.value)

      # Check each reference against the known list
      ivar_references.each do |ivar_node|
        ivar_name = ivar_node.name

        # Skip if it's a known instance variable or our internal variable
        next if @__ivar_known_ivars.include?(ivar_name) || ivar_name == :@__ivar_known_ivars

        # Generate a warning with a suggestion
        line_number = ivar_node.location.start_line
        suggestion = DidYouMean::SpellChecker.new(dictionary: @__ivar_known_ivars).correct(ivar_name).first
        suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""

        warn "#{source_file}:#{line_number}: warning: unknown instance variable #{ivar_name}. #{suggestion_text}"
      end
    end

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
  end

  # Module for automatically checking instance variables
  module CheckedIvars
    def self.included(base)
      base.prepend(InitializeWrapper)
    end

    # Module to wrap the initialize method
    module InitializeWrapper
      def initialize(*)
        # Track instance variables before initialization
        instance_variables

        # Call the original initialize method
        super

        # Track instance variables after initialization
        post_init_ivars = instance_variables

        # Store the known instance variables
        @__ivar_known_ivars = post_init_ivars

        # Audit the class for unknown instance variables
        audit_class_for_unknown_ivars
      end

      private

      # Use Prism to parse the class definition and find all instance variable references
      def audit_class_for_unknown_ivars
        # Get the class source file
        source_file = self.class.instance_method(:initialize).source_location[0]
        source_code = File.read(source_file)

        # Parse the source code
        result = Prism.parse(source_code)

        # Find all instance variable references
        ivar_references = find_ivar_references(result.value)

        # Check each reference against the known list
        ivar_references.each do |ivar_node|
          ivar_name = ivar_node.name

          # Skip if it's a known instance variable or our internal variable
          next if @__ivar_known_ivars.include?(ivar_name) || ivar_name == :@__ivar_known_ivars

          # Generate a warning with a suggestion
          line_number = ivar_node.location.start_line
          suggestion = DidYouMean::SpellChecker.new(dictionary: @__ivar_known_ivars).correct(ivar_name).first
          suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""

          warn "#{source_file}:#{line_number}: warning: unknown instance variable #{ivar_name}. #{suggestion_text}"
        end
      end

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
    end
  end
end
