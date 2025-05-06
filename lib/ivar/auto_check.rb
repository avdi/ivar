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
        # Get the manifest for this class
        manifest = Ivar.get_manifest(self.class)

        # We'll pass kwargs directly to process_before_init
        # which will modify it by removing used kwargs

        # Process before_init callbacks
        # This will handle initialization from kwargs and initial values
        # and remove used kwargs from the hash
        manifest.process_before_init(self, args, kwargs)

        # Track initialized variables before calling super
        track_initialized_instance_variables

        # Track the instance variables before initialization
        pre_init_ivars = instance_variables.dup

        # Call the original initialize method
        super

        # Track the instance variables after initialization
        post_init_ivars = instance_variables

        # Find new instance variables that were set during initialization
        new_ivars = post_init_ivars - pre_init_ivars

        # Create implicit declarations for new instance variables
        new_ivars.each do |ivar_name|
          next if Ivar.internal_ivar?(ivar_name)
          declaration = ImplicitDeclaration.new(ivar_name)
          manifest.add_implicit_declaration(declaration)
        end

        # Check for unknown instance variables
        check_ivars
      end

      private

      # Track which instance variables have been set so far
      # This prevents parent initialize methods from overwriting values
      # that were set from keyword arguments
      def track_initialized_instance_variables
        @__ivar_initialized_vars = instance_variables.dup
      end

      # Valid initialization methods for keyword arguments
      KWARG_INIT_METHODS = [:kwarg, :keyword].freeze
    end
  end
end
