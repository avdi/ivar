# frozen_string_literal: true

require_relative "validation"
require_relative "macros"
require_relative "check_policy"
require_relative "checked/class_methods"
require_relative "checked/instance_methods"

module Ivar
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
  end
end
