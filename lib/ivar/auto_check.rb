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
        # Getter - return the current policy
        @__ivar_check_policy || Ivar.check_policy
      else
        # Setter - set the policy
        @__ivar_check_policy = options.empty? ? policy : [policy, options]
      end
    end

    # Hook method called when the module is included
    def inherited(subclass)
      super
      # Copy the check policy to the subclass
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
      base.include(PreInitializeIvars)
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
        # Ensure subclasses also get the initialize wrapper
        subclass.prepend(Ivar::Checked::InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      def initialize(*args, **kwargs, &block)
        # Initialize pre-declared instance variables
        initialize_pre_declared_ivars

        # Call the original initialize method with all arguments
        super

        # Automatically check instance variables
        check_ivars
      end
    end
  end
end
