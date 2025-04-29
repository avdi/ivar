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

    # Find all instance variable references in a class
    def find_all_ivar_references(klass)
      # Get the source file from the initialize method
      source_file = klass.instance_method(:initialize).source_location[0]

      # Read the source code
      source_code = File.read(source_file)

      # Parse the source code
      result = Prism.parse(source_code)

      # Find all instance variable references in the entire file
      all_references = find_ivar_references(result.value)

      # Get all methods defined in the class
      method_names = klass.instance_methods(false)

      # For each method, get its source location and scan for instance variables
      method_names.each do |method_name|
        # Skip if the method is not defined in the class
        next unless klass.instance_method(method_name).owner == klass

        # Get the method's source location
        method_source_file = klass.instance_method(method_name).source_location&.first
        next unless method_source_file

        # If the method is defined in a different file, read that file
        if method_source_file != source_file
          method_source_code = File.read(method_source_file)
          method_result = Prism.parse(method_source_code)
          all_references.concat(find_ivar_references(method_result.value))
        end
      end

      all_references
    end

    # Check for unknown instance variables
    def check_for_unknown_ivars(klass, known_ivars)
      # Find all instance variable references
      ivar_references = find_all_ivar_references(klass)

      # Get the source file from the initialize method
      source_file = klass.instance_method(:initialize).source_location[0]

      # Check each reference against the known list
      ivar_references.each do |ivar_node|
        ivar_name = ivar_node.name

        # Skip if it's a known instance variable or our internal variable
        next if known_ivars.include?(ivar_name) || ivar_name == :@__ivar_known_ivars

        # Generate a warning with a suggestion
        line_number = ivar_node.location.start_line
        suggestion = DidYouMean::SpellChecker.new(dictionary: known_ivars).correct(ivar_name).first
        suggestion_text = suggestion ? "Did you mean: #{suggestion}?" : ""

        warn "#{source_file}:#{line_number}: warning: unknown instance variable #{ivar_name}. #{suggestion_text}"
      end
    end

    # Get all known instance variables from the class hierarchy
    def get_all_known_ivars(klass)
      return [] unless klass.respond_to?(:known_ivars)

      # Get known ivars from the current class
      known_ivars = klass.known_ivars || []

      # Get known ivars from the parent class
      if klass.superclass.respond_to?(:known_ivars) && klass.superclass.known_ivars
        known_ivars += get_all_known_ivars(klass.superclass)
      end

      known_ivars.uniq
    end
  end

  # Module for class-level instance variable tracking and checking
  module IvarClassTools
    include IvarFinder

    # Initialize class variables for tracking instance variables
    def init_ivar_tracking
      class_variable_set(:@@__ivar_known_ivars, nil)
      class_variable_set(:@@__ivar_checked, false)
    end

    # Get the known instance variables
    def known_ivars
      class_variable_get(:@@__ivar_known_ivars)
    end

    # Set the known instance variables
    def known_ivars=(value)
      class_variable_set(:@@__ivar_known_ivars, value)
    end

    # Check if the class has been checked for unknown instance variables
    def checked?
      class_variable_get(:@@__ivar_checked)
    end

    # Mark the class as checked for unknown instance variables
    def mark_as_checked
      class_variable_set(:@@__ivar_checked, true)
    end

    # Update the known instance variables with new ones
    def update_known_ivars(new_ivars, add = [])
      self.known_ivars = if known_ivars.nil?
        new_ivars + add
      else
        (known_ivars + new_ivars + add).uniq
      end
    end

    # Check for unknown instance variables
    def check_for_unknown_ivars_in_class(all_known_ivars)
      check_for_unknown_ivars(self, all_known_ivars)
      mark_as_checked
    end
  end

  # Module for tracking and checking instance variables
  module IvarTools
    def self.included(base)
      base.extend(IvarClassTools)
      base.init_ivar_tracking
    end

    # Check instance variables for misspellings
    # @param add [Array<Symbol>] Additional instance variables to consider as known
    def check_ivars(add: [])
      # Get the current list of instance variables
      current_ivars = instance_variables

      # Update the known instance variables
      self.class.update_known_ivars(current_ivars, add)

      # If the class hasn't been checked yet, check for unknown instance variables
      unless self.class.checked?
        # Get all known instance variables from the class hierarchy
        all_known_ivars = self.class.get_all_known_ivars(self.class)

        # Check for unknown instance variables
        self.class.check_for_unknown_ivars_in_class(all_known_ivars)
      end
    end
  end

  # Module for automatically checking instance variables
  module CheckedIvars
    def self.included(base)
      base.extend(IvarClassTools)
      base.init_ivar_tracking
      base.prepend(InitializeWrapper)
    end

    # Module to wrap the initialize method
    module InitializeWrapper
      include IvarFinder

      def initialize(*)
        # Call the original initialize method
        super

        # Get the current list of instance variables
        current_ivars = instance_variables

        # Update the known instance variables
        self.class.update_known_ivars(current_ivars)

        # If the class hasn't been checked yet, check for unknown instance variables
        unless self.class.checked?
          # Get all known instance variables from the class hierarchy
          all_known_ivars = self.class.get_all_known_ivars(self.class)

          # Check for unknown instance variables
          self.class.check_for_unknown_ivars_in_class(all_known_ivars)
        end
      end
    end
  end
end
