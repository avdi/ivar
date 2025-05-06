# frozen_string_literal: true

require_relative "validation"
require_relative "macros"

module Ivar
  # Module for adding instance variable check policy configuration to classes.
  # This module provides a way to set and inherit check policies for instance variables.
  # When extended in a class, it allows setting a class-specific policy that overrides
  # the global Ivar policy.
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
    # This method is called automatically when a class is inherited
    # @param subclass [Class] The subclass that is inheriting from this class
    def inherited(subclass)
      super
      subclass.instance_variable_set(:@__ivar_check_policy, @__ivar_check_policy)
    end
  end

  # Provides automatic validation for instance variables.
  # When included in a class, this module:
  # 1. Automatically calls check_ivars after initialization
  # 2. Extends the class with CheckPolicy for policy configuration
  # 3. Extends the class with Macros for ivar declarations
  # 4. Sets a default check policy of :warn
  # 5. Handles proper inheritance of these behaviors in subclasses
  module Checked
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    # @param base [Class] The class that is including this module
    def self.included(base)
      base.include(Validation)
      base.extend(ClassMethods)
      base.extend(CheckPolicy)
      base.extend(Macros)
      base.prepend(InstanceMethods)

      # Set default policy for Checked to :warn
      # This can be overridden by calling ivar_check_policy in the class
      base.ivar_check_policy(:warn)
    end

    # Class methods added to the including class.
    # These methods ensure proper inheritance of Checked functionality.
    module ClassMethods
      # Ensure subclasses inherit the Checked functionality
      # This method is called automatically when a class is inherited
      # @param subclass [Class] The subclass that is inheriting from this class
      def inherited(subclass)
        super
        subclass.prepend(Ivar::Checked::InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class.
    # These methods provide the core functionality for automatic instance variable validation.
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      # This method handles the initialization process, including:
      # 1. Processing manifest declarations before calling super
      # 3. Checking instance variables for validity
      def initialize(*args, **kwargs, &block)
        if @__ivar_skip_init
          super
        else
          @__ivar_skip_init = true
          manifest = Ivar.get_manifest(self.class)
          manifest.process_before_init(self, args, kwargs)
          super
          check_ivars
        end
      end

      private

      # Valid initialization methods for keyword arguments
      # These are the allowed values for the :init option in ivar declarations
      # Used to identify instance variables that should be initialized from keyword arguments
      KWARG_INIT_METHODS = [:kwarg, :keyword].freeze
    end
  end
end
