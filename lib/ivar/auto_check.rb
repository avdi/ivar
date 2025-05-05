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
        initialize_declared_ivars
        remaining_kwargs = initialize_from_kwargs(kwargs)
        super(*args, **remaining_kwargs, &block)
        check_ivars
      end

      private

      # Initialize declared instance variables with their initial values
      def initialize_declared_ivars
        return unless self.class.respond_to?(:ivar_initial_values)

        # Get the initial values for declared instance variables
        initial_values = self.class.ivar_initial_values

        # Set each instance variable to its initial value
        initial_values.each do |ivar_name, value|
          instance_variable_set(ivar_name, value)
        end
      end

      # Valid initialization methods for keyword arguments
      KWARG_INIT_METHODS = [:kwarg, :keyword].freeze

      # Initialize instance variables from keyword arguments
      # @param kwargs [Hash] Keyword arguments passed to initialize
      # @return [Hash] Remaining keyword arguments after peeling off those used for ivar initialization
      def initialize_from_kwargs(kwargs)
        return kwargs unless self.class.respond_to?(:ivar_init_methods)

        # Get the initialization methods for declared instance variables
        init_methods = self.class.ivar_init_methods

        # Create a copy of kwargs that we'll modify
        remaining_kwargs = kwargs.dup

        # Process each ivar with an init method
        init_methods.each do |ivar_name, init_method|
          next unless KWARG_INIT_METHODS.include?(init_method)

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
    end
  end
end
