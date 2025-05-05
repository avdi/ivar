# frozen_string_literal: true

require_relative "validation"
require_relative "macros"

module Ivar
  # Module for adding ivar_check_policy to classes
  module CheckPolicy
    # When this module is extended, declare its internal instance variables
    def self.extended(base)
      if base.respond_to?(:ivar)
        base.ivar :@__ivar_check_policy
      end
    end

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

        if subclass.respond_to?(:ivar)
          subclass.ivar :@__ivar_check_policy
        end
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      def initialize(*args, **kwargs, &block)
        initialize_declared_ivars
        super
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
    end
  end
end
