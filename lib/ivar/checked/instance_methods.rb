# frozen_string_literal: true

module Ivar
  module Checked
    # Instance methods that will be prepended to the including class.
    # These methods provide the core functionality for automatic instance variable validation.
    module InstanceMethods
      # The semantics of prepend are such that the super method becomes wholly inaccessible. So if we override a method
      # (like, say, initialize), we have to stash the original method implementation if we ever want to find out its
      # file and line number.
      def self.prepend_features(othermod)
        (instance_methods(false) | private_instance_methods(false)).each do |method_name|
          Ivar.stash_method(othermod, method_name)
        end
        super
      end

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
    end
  end
end
