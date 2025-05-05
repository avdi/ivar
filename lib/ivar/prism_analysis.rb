# frozen_string_literal: true

require "prism"

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
    # Each hash includes var name, path, line number, and column number
    def ivar_references
      @references
    end

    private

    def collect_references
      instance_source_files = collect_instance_method_source_files
      class_source_files = collect_class_method_source_files

      @references = []
      process_source_files(instance_source_files, :instance)
      process_source_files(class_source_files, :class)
    end

    def process_source_files(source_files, context)
      source_files.each do |file_path|
        code = File.read(file_path)
        result = Prism.parse(code)
        visitor = IvarReferenceVisitor.new(file_path, context)
        result.value.accept(visitor)
        @references.concat(visitor.references)
      end
    end

    def unique_ivar_names
      @references.map { |ref| ref[:name] }.uniq.sort
    end

    def collect_instance_method_source_files
      instance_methods = @klass.instance_methods(false) | @klass.private_instance_methods(false)
      collect_method_source_files(instance_methods) do |method_name|
        @klass.instance_method(method_name)
      end
    end

    def collect_class_method_source_files
      class_methods = @klass.singleton_methods(false)
      collect_method_source_files(class_methods) do |method_name|
        @klass.method(method_name)
      end
    end

    def collect_method_source_files(method_names)
      source_files = Set.new
      method_names.each do |method_name|
        method_obj = yield(method_name)
        next unless method_obj.source_location

        source_files << method_obj.source_location.first
      end
      source_files
    end

    # Visitor that collects instance variable references with location information
    class IvarReferenceVisitor < Prism::Visitor
      attr_reader :references

      def initialize(file_path, context = :instance)
        super()
        @file_path = file_path
        @references = []
        @context = context # :instance or :class
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
          context: @context # Add the context (instance or class)
        }

        @references << reference
      end
    end
  end
end
