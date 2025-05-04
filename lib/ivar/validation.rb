# frozen_string_literal: true

require "did_you_mean"

module Ivar
  # Provides validation for instance variables
  module Validation
    # Checks instance variables against class analysis
    # @param add [Array<Symbol>] Additional instance variables to allow
    # @param policy [Symbol, Policy] The policy to use for handling unknown variables
    def check_ivars(add: [], policy: nil)
      # Get the policy to use
      policy ||= get_check_policy

      # Get the class analysis from the cache
      analysis = Ivar.get_analysis(self.class)

      # Get all instance variables defined in the current object
      # These are the ones the user has explicitly defined before calling check_ivars
      defined_ivars = instance_variables.map(&:to_sym)

      # Get all declared instance variables from the class hierarchy
      declared_ivars = collect_declared_ivars

      # Add any additional allowed variables
      allowed_ivars = defined_ivars + declared_ivars + add

      # Get all instance variable references from the analysis
      # This includes location information for each reference
      references = analysis.ivar_references

      # Add internal instance variables to the allowed list
      internal_ivars = [:@__ivar_check_policy, :@__ivar_declared_ivars, :@__ivar_initial_values]
      allowed_ivars += internal_ivars

      # Get class-level instance variables (defined on the class itself)
      class_level_ivars = self.class.instance_variables.map(&:to_sym)

      # Get class method names to check for class-level instance variables
      class_methods = self.class.methods(false) | self.class.private_methods(false)

      # Get class-level instance variables referenced in class methods
      class_method_ivars = collect_class_method_ivars(class_methods)

      # Add class-level instance variables to the allowed list
      allowed_ivars += class_level_ivars + class_method_ivars

      # Find references to unknown variables (those not in allowed_ivars)
      unknown_refs = references.reject { |ref| allowed_ivars.include?(ref[:name]) }

      # Handle unknown variables according to the policy
      policy_instance = Ivar.get_policy(policy)
      policy_instance.handle_unknown_ivars(unknown_refs, self.class, allowed_ivars)
    end

    private

    # Get the check policy for this instance
    # @return [Symbol, Policy] The check policy
    def get_check_policy
      # If the class has an ivar_check_policy method, use that
      return self.class.ivar_check_policy if self.class.respond_to?(:ivar_check_policy)

      # Otherwise, use the global default
      Ivar.check_policy
    end

    # Collect all declared instance variables from the class hierarchy
    # @return [Array<Symbol>] All declared instance variables
    def collect_declared_ivars
      klass = self.class
      declared_ivars = []

      # Walk up the inheritance chain
      while klass
        # If the class responds to ivar_declared, add its declared ivars
        if klass.respond_to?(:ivar_declared)
          declared_ivars.concat(klass.ivar_declared)
        end

        # Move up to the superclass
        klass = klass.superclass
      end

      declared_ivars.uniq
    end

    # Collect instance variables referenced in class methods
    # @param class_methods [Array<Symbol>] Class method names to check
    # @return [Array<Symbol>] Instance variables referenced in class methods
    def collect_class_method_ivars(class_methods)
      class_method_ivars = []

      # For each class method, try to extract its source and analyze it for instance variables
      class_methods.each do |method_name|
        # Skip methods without source location (built-in methods)
        next unless self.class.method(method_name).source_location

        begin
          # Get the method object
          method_obj = self.class.method(method_name)

          # Get the source file
          source_file = method_obj.source_location&.first
          next unless source_file && File.exist?(source_file)

          # Read the source file
          source = File.read(source_file)

          # Parse the source with Prism
          result = Prism.parse(source)

          # Create a visitor to collect instance variables
          visitor = ClassMethodIvarVisitor.new

          # Visit the AST to collect instance variables
          result.value.accept(visitor)

          # Add the collected instance variables to our list
          class_method_ivars.concat(visitor.ivars)
        rescue
          # If anything goes wrong, just continue to the next method
          next
        end
      end

      class_method_ivars.uniq
    end

    # Visitor that collects instance variable references in class methods
    class ClassMethodIvarVisitor < Prism::Visitor
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
