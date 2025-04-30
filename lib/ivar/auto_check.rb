# frozen_string_literal: true

require_relative "validation"
require_relative "macros"

module Ivar
  # Provides automatic validation for instance variables
  # When included, automatically calls check_ivars after initialization
  module Checked
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.include(PreInitializeIvars)
      base.extend(ClassMethods)
      base.extend(Macros)
      base.prepend(InstanceMethods)
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
      def initialize(...)
        # Initialize pre-declared instance variables
        initialize_pre_declared_ivars
        # Call the original initialize method
        super
        # Automatically check instance variables
        check_ivars
      end
    end
  end

  # Provides automatic validation for instance variables, but only once per class
  # When included, automatically calls check_ivars_once after initialization
  module CheckedOnce
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.include(PreInitializeIvars)
      base.extend(ClassMethods)
      base.extend(Macros)
      base.prepend(InstanceMethods)
    end

    # Class methods added to the including class
    module ClassMethods
      # Hook method called when the module is included
      def inherited(subclass)
        super
        # Ensure subclasses also get the initialize wrapper
        subclass.prepend(Ivar::CheckedOnce::InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars_once
      def initialize(...)
        # Initialize pre-declared instance variables
        initialize_pre_declared_ivars
        # Call the original initialize method
        super
        # Automatically check instance variables once
        check_ivars_once
      end
    end
  end
end
