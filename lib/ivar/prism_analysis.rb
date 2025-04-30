# frozen_string_literal: true

require 'prism'
require 'set'

module Ivar
  # Analyzes a class to find all instance variables using Prism
  class PrismAnalysis
    attr_reader :ivars

    def initialize(klass)
      @klass = klass
      @references = nil
      collect_references
      @ivars = unique_ivar_names
    end

    # Returns a list of hashes each representing a code reference to an ivar
    # Each hash includes var name, path, and line number (and column if available)
    def ivar_references
      @references
    end

    private

    def collect_references
      source_files = collect_source_files
      @references = []

      source_files.each do |file_path|
        code = File.read(file_path)
        result = Prism.parse(code)
        visitor = IvarReferenceVisitor.new(file_path)
        result.value.accept(visitor)
        @references.concat(visitor.references)
      end
    end

    def unique_ivar_names
      @references.map { |ref| ref[:name] }.uniq.sort
    end

    def collect_source_files
      # Get all instance methods
      instance_methods = @klass.instance_methods(false) | @klass.private_instance_methods(false)

      # Collect source files for all methods
      source_files = Set.new
      instance_methods.each do |method_name|
        next unless @klass.instance_method(method_name).source_location

        source_files << @klass.instance_method(method_name).source_location.first
      end

      source_files
    end

    # Visitor that collects instance variable references with location information
    class IvarReferenceVisitor < Prism::Visitor
      attr_reader :references

      def initialize(file_path)
        super()
        @file_path = file_path
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
          line: location.start_line
        }

        # Add column if available
        reference[:column] = location.start_column if location.respond_to?(:start_column)

        @references << reference
      end
    end
  end
end
