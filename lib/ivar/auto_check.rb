# frozen_string_literal: true

require_relative "validation"
require_relative "macros"

module Ivar
  # Module for adding instance variable check policy configuration to classes
  module CheckPolicy
    # Set or get the check policy for this class
    # @param policy [Symbol, Policy] The check policy to set
    # @param options [Hash] Additional options for the policy
    # @return [Symbol, Policy] The current check policy
    def ivar_check_policy(policy = nil, **options)
      if policy.nil?
        @__ivar_check_policy || Ivar.check_policy
      else
        @__ivar_check_policy = options.empty? ? policy : [policy, options]
      end
    end

    # Ensure subclasses inherit the check policy from their parent
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
      # Ensure subclasses inherit the Checked functionality
      def inherited(subclass)
        super
        subclass.prepend(Ivar::Checked::InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      def initialize(*args, **kwargs, &block)
        initialize_declared_ivars
        remaining_kwargs = initialize_from_kwargs(kwargs)
        track_initialized_instance_variables
        super(*args, **remaining_kwargs, &block)
        check_ivars
      end

      private

      # Track which instance variables have been set so far
      # This prevents parent initialize methods from overwriting values
      # that were set from keyword arguments
      def track_initialized_instance_variables
        @__ivar_initialized_vars = instance_variables.dup
      end

      # Initialize declared instance variables with their initial values
      # This applies defaults from the entire ancestor chain, with child defaults
      # taking precedence over parent defaults
      def initialize_declared_ivars
        initialized_vars = instance_variable_defined?(:@__ivar_initialized_vars) ? @__ivar_initialized_vars : []

        ancestor_initial_values.each do |ivar_name, value|
          initialized_vars.include?(ivar_name) or instance_variable_set(ivar_name, value)
        end
      end

      # Find all ancestors that have defined initial values for instance variables
      # @return [Array<Class>] Array of ancestor classes with initial values
      def find_ancestors_with_initial_values
        self.class.ancestors.select do |ancestor|
          ancestor.respond_to?(:ivar_initial_values) &&
            ancestor.instance_variable_defined?(:@__ivar_initial_values)
        end
      end

      # Apply initial values from ancestors to the result hash
      # @param ancestors [Array<Class>] Ancestors with initial values
      def ancestor_initial_values(ancestors = find_ancestors_with_initial_values)
        ancestors.reverse.reduce({}) do |result, ancestor|
          result.merge!(ancestor.ivar_initial_values)
        end
      end

      # Valid initialization methods for keyword arguments
      KWARG_INIT_METHODS = [:kwarg, :keyword].freeze

      # Initialize instance variables from keyword arguments
      # This applies keyword arguments to ivars from the entire ancestor chain,
      # with child declarations taking precedence over parent declarations
      # @param kwargs [Hash] Keyword arguments passed to initialize
      # @return [Hash] Remaining keyword arguments after peeling off those used for ivar initialization
      def initialize_from_kwargs(kwargs)
        all_kwarg_ivars = collect_kwarg_ivars_from_ancestors
        remaining_kwargs = kwargs.dup
        apply_kwargs_to_ivars(all_kwarg_ivars, remaining_kwargs)
        remaining_kwargs
      end

      # Apply keyword arguments to instance variables
      # @param ivar_names [Array<Symbol>] Instance variable names
      # @param kwargs [Hash] Keyword arguments
      def apply_kwargs_to_ivars(ivar_names, kwargs)
        ivar_names.each do |ivar_name|
          kwarg_name = ivar_name.to_s.delete_prefix("@").to_sym
          if kwargs.key?(kwarg_name)
            instance_variable_set(ivar_name, kwargs[kwarg_name])
            kwargs.delete(kwarg_name)
          end
        end
      end

      # Collect all keyword-initialized ivars from the entire ancestor chain
      # @return [Array<Symbol>] An array of instance variable names
      def collect_kwarg_ivars_from_ancestors(ancestors = find_ancestors_with_init_methods)
        collect_kwarg_ivars_from_ancestors_list(ancestors)
      end

      # Find all ancestors that have defined initialization methods
      # @return [Array<Class>] Array of ancestor classes with init methods
      def find_ancestors_with_init_methods
        self.class.ancestors.select do |ancestor|
          ancestor.respond_to?(:ivar_init_methods) &&
            ancestor.instance_variable_defined?(:@__ivar_init_methods)
        end
      end

      # Collect keyword-initialized ivars from the given ancestors
      # @param ancestors [Array<Class>] Ancestors with init methods
      def collect_kwarg_ivars_from_ancestors_list(ancestors)
        ancestors.reverse.flat_map { |ancestor|
          init_methods = ancestor.ivar_init_methods
          init_methods.filter_map { |ivar_name, init_method|
            case init_method
            when *KWARG_INIT_METHODS then ivar_name
            end
          }
        }.uniq
      end
    end
  end
end
