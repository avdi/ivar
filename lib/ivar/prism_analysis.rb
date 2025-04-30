# frozen_string_literal: true

require "prism"

module Ivar
  # Analyzes a class to find all instance variables using Prism
  class PrismAnalysis
    attr_reader :ivars

    def initialize(klass)
      @klass = klass
      @ivars = analyze_class
    end

    private

    def analyze_class
      code = source_code
      return [] unless code

      result = Prism.parse(code)
      extract_ivars(result.value)
    end

    def source_code
      source_location = @klass.instance_method(:initialize).source_location&.first
      return nil unless source_location

      File.read(source_location)
    end

    def extract_ivars(program)
      visitor = IvarVisitor.new
      program.accept(visitor)
      visitor.ivars.uniq.sort
    end

    # Visitor that collects instance variable references from Prism AST
    class IvarVisitor < Prism::Visitor
      attr_reader :ivars

      def initialize
        super
        @ivars = []
      end

      def visit_instance_variable_read_node(node)
        @ivars << node.name.to_sym
        true
      end

      def visit_instance_variable_write_node(node)
        @ivars << node.name.to_sym
        true
      end

      def visit_instance_variable_operator_write_node(node)
        @ivars << node.name.to_sym
        true
      end

      def visit_instance_variable_target_node(node)
        @ivars << node.name.to_sym
        true
      end
    end
  end
end
