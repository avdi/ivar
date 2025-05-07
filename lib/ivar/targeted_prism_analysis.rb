# frozen_string_literal: true

require "prism"

module Ivar
  # Analyzes a class to find instance variable references in specific instance methods
  # Unlike PrismAnalysis, this targets only the class's own methods (not inherited)
  # and precisely locates instance variable references within each method definition
  class TargetedPrismAnalysis
    attr_reader :ivars, :references

    def initialize(klass)
      @klass = klass
      @references = []
      @method_locations = {}
      collect_method_locations
      analyze_methods
      @ivars = unique_ivar_names
    end

    # Returns a list of hashes each representing a code reference to an ivar
    # Each hash includes var name, path, line number, and column number
    def ivar_references
      @references
    end

    private

    def unique_ivar_names
      @references.map { |ref| ref[:name] }.uniq.sort
    end

    def collect_method_locations
      # Get all instance methods defined directly on this class (not inherited)
      instance_methods = @klass.instance_methods(false) | @klass.private_instance_methods(false)
      instance_methods.each do |method_name|
        # Try to get the method from the stash first, then fall back to the current method
        method_obj = Ivar.retrieve_method(@klass, method_name) || @klass.instance_method(method_name)
        next unless method_obj.source_location

        file_path, line_number = method_obj.source_location
        @method_locations[method_name] = {path: file_path, line: line_number}
      end
    end

    def analyze_methods
      # Group methods by file to avoid parsing the same file multiple times
      methods_by_file = @method_locations.group_by { |_, location| location[:path] }

      methods_by_file.each do |file_path, methods_in_file|
        code = File.read(file_path)
        result = Prism.parse(code)

        methods_in_file.each do |method_name, location|
          visitor = MethodTargetedInstanceVariableReferenceVisitor.new(
            file_path,
            method_name,
            location[:line]
          )

          result.value.accept(visitor)
          @references.concat(visitor.references)
        end
      end
    end
  end

  # Visitor that collects instance variable references within a specific method definition
  class MethodTargetedInstanceVariableReferenceVisitor < Prism::Visitor
    attr_reader :references

    def initialize(file_path, target_method_name, target_line)
      super()
      @file_path = file_path
      @target_method_name = target_method_name
      @target_line = target_line
      @references = []
      @in_target_method = false
    end

    # Only visit the method definition we're targeting
    def visit_def_node(node)
      # Check if this is our target method
      if node.name.to_sym == @target_method_name && node.location.start_line == @target_line
        # Found our target method, now collect all instance variable references within it
        collector = IvarCollector.new(@file_path, @target_method_name)
        node.body&.accept(collector)
        @references = collector.references
        false
      else
        # Sometimes methods are found inside other methods...
        node.body&.accept(self)
        true
      end
    end
  end

  # Helper visitor that collects all instance variable references
  class IvarCollector < Prism::Visitor
    attr_reader :references

    def initialize(file_path, method_name)
      super()
      @file_path = file_path
      @method_name = method_name
      @references = []
    end

    def visit_instance_variable_read_node(node)
      add_reference(node)
      true
    end

    def visit_instance_variable_write_node(node)
      add_reference(node)
      true
    end

    def visit_instance_variable_operator_write_node(node)
      add_reference(node)
      true
    end

    def visit_instance_variable_target_node(node)
      add_reference(node)
      true
    end

    private

    def add_reference(node)
      location = node.location
      reference = {
        name: node.name.to_sym,
        path: @file_path,
        line: location.start_line,
        column: location.start_column,
        method: @method_name
      }

      @references << reference
    end
  end
end
