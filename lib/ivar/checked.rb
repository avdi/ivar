# frozen_string_literal: true

require_relative "validation"

module Ivar
  # Provides automatic validation for instance variables
  # When included, automatically checks instance variables after initialization
  module Checked
    # When this module is included in a class, it extends the class
    # with ClassMethods and includes the Validation module
    def self.included(base)
      base.include(Validation)
      base.extend(ClassMethods)
      base.prepend(InstanceMethods)
    end

    # Class methods added to the including class
    module ClassMethods
      # Hook method called when the module is included
      def inherited(subclass)
        super
        subclass.prepend(InstanceMethods)
      end
    end

    # Instance methods that will be prepended to the including class
    module InstanceMethods
      # Wrap the initialize method to automatically call check_ivars
      def initialize(*args, **kwargs, &block)
        super
        check_ivars(policy: :warn_once)
      end
    end
  end
end
