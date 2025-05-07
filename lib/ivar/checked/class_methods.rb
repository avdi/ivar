# frozen_string_literal: true

require_relative "instance_methods"

module Ivar
  module Checked
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
  end
end
