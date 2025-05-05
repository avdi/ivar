# frozen_string_literal: true

require_relative "validation"
require_relative "macros"

module Ivar
  # Module for adding ivar_check_policy to classes
  module CheckPolicy
    # Set the check policy for this class
    # @param policy [Symbol, Policy] The check policy
    # @return [Symbol, Policy] The check policy
    def ivar_check_policy(policy = nil, **options)
      if policy.nil?
        @__ivar_check_policy || Ivar.check_policy
      else
        @__ivar_check_policy = options.empty? ? policy : [policy, options]
      end
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      subclass.instance_variable_set(:@__ivar_check_policy, @__ivar_check_policy)
    end
  end

  # Provides automatic validation for instance variables
  # When included, automatically calls check_ivars after initialization
  module Checked
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.extend(ClassMethods)
      base.extend(CheckPolicy)
      base.extend(Macros)
      base.prepend(InstanceMethods)

      # Set default policy for Checked to :warn
      base.ivar_check_policy(:warn)
    end

    # Class methods added to the including class
    module ClassMethods
      # Hook method called when the module is included
      def inherited(subclass)
        super
        subclass.prepend(Ivar::Checked::InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      def initialize(*args, **kwargs, &block)
        # First, apply default values to all declared instance variables
        initialize_declared_ivars

        # Then, apply keyword arguments (which will override defaults)
        remaining_kwargs = initialize_from_kwargs(kwargs)

        # Track which instance variables have been set so far
        # This prevents parent initialize methods from overwriting values
        # that were set from keyword arguments
        @__ivar_initialized_vars = instance_variables.dup

        # Call the original initialize method with remaining kwargs
        super(*args, **remaining_kwargs, &block)

        # Finally, check for any undeclared instance variables
        check_ivars
      end

      private

      # Initialize declared instance variables with their initial values
      # This applies defaults from the entire ancestor chain, with child defaults
      # taking precedence over parent defaults
      def initialize_declared_ivars
        # Skip if we've already initialized variables (in parent class)
        initialized_vars = instance_variable_defined?(:@__ivar_initialized_vars) ?
                           @__ivar_initialized_vars : []

        # Collect all initial values from the entire ancestor chain
        all_initial_values = collect_initial_values_from_ancestors

        # Set each instance variable to its initial value, but only if it hasn't been set already
        all_initial_values.each do |ivar_name, value|
          unless initialized_vars.include?(ivar_name)
            instance_variable_set(ivar_name, value)
          end
        end
      end

      # Collect initial values from the entire ancestor chain
      # @return [Hash] A hash of instance variable names to their initial values
      def collect_initial_values_from_ancestors
        all_initial_values = {}

        # Start with the topmost ancestor and work down to the current class
        # This ensures that child defaults override parent defaults
        ancestors_with_initial_values = self.class.ancestors.select do |ancestor|
          ancestor.respond_to?(:ivar_initial_values) &&
            ancestor.instance_variable_defined?(:@__ivar_initial_values)
        end

        # Process ancestors in reverse order (from parent to child)
        ancestors_with_initial_values.reverse_each do |ancestor|
          # Merge in the initial values from this ancestor
          # Later values (from child classes) will override earlier ones
          all_initial_values.merge!(ancestor.ivar_initial_values)
        end

        all_initial_values
      end

      # Valid initialization methods for keyword arguments
      KWARG_INIT_METHODS = [:kwarg, :keyword].freeze

      # Initialize instance variables from keyword arguments
      # This applies keyword arguments to ivars from the entire ancestor chain,
      # with child declarations taking precedence over parent declarations
      # @param kwargs [Hash] Keyword arguments passed to initialize
      # @return [Hash] Remaining keyword arguments after peeling off those used for ivar initialization
      def initialize_from_kwargs(kwargs)
        # Collect all keyword-initialized ivars from the entire ancestor chain
        all_kwarg_ivars = collect_kwarg_ivars_from_ancestors

        # Create a copy of kwargs that we'll modify
        remaining_kwargs = kwargs.dup

        # Process each ivar with a kwarg init method
        all_kwarg_ivars.each do |ivar_name|
          # Convert @var_name to var_name for keyword lookup
          kwarg_name = ivar_name.to_s.delete_prefix("@").to_sym

          # If the keyword argument is present, set the instance variable
          # and remove it from the remaining kwargs
          if remaining_kwargs.key?(kwarg_name)
            instance_variable_set(ivar_name, remaining_kwargs[kwarg_name])
            remaining_kwargs.delete(kwarg_name)
          end
        end

        remaining_kwargs
      end

      # Collect all keyword-initialized ivars from the entire ancestor chain
      # @return [Array<Symbol>] An array of instance variable names
      def collect_kwarg_ivars_from_ancestors
        all_kwarg_ivars = []

        # Start with the topmost ancestor and work down to the current class
        ancestors_with_init_methods = self.class.ancestors.select do |ancestor|
          ancestor.respond_to?(:ivar_init_methods) &&
            ancestor.instance_variable_defined?(:@__ivar_init_methods)
        end

        # Process ancestors in reverse order (from parent to child)
        ancestors_with_init_methods.reverse_each do |ancestor|
          # Get the initialization methods for this ancestor
          init_methods = ancestor.ivar_init_methods

          # Add any keyword-initialized ivars to our list
          init_methods.each do |ivar_name, init_method|
            if KWARG_INIT_METHODS.include?(init_method)
              # Add to our list if not already present (child overrides parent)
              all_kwarg_ivars << ivar_name unless all_kwarg_ivars.include?(ivar_name)
            end
          end
        end

        all_kwarg_ivars
      end
    end
  end
end
