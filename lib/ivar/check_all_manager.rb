# frozen_string_literal: true

require "pathname"

module Ivar
  # Manages automatic inclusion of Ivar::Checked in classes and modules
  class CheckAllManager
    def initialize
      @trace_point = nil
      @mutex = Mutex.new
    end

    # Enables automatic inclusion of Ivar::Checked in all classes and modules
    # defined within the project root.
    #
    # @param project_root [String] The project root directory path
    # @param block [Proc] Optional block. If provided, auto-checking is only active
    #   for the duration of the block. Otherwise, it remains active indefinitely.
    # @return [void]
    def enable(project_root, &block)
      # If a trace point is already active, disable it first
      disable if @trace_point

      # Convert project root to Pathname for easier path operations
      root_pathname = Pathname.new(project_root)

      # Create a new trace point that triggers on class/module definition
      @mutex.synchronize do
        @trace_point = TracePoint.new(:class) do |tp|
          # Skip if we can't determine the path (e.g., classes defined in eval)
          next unless tp.path

          # Get the absolute path of the file where the class is defined
          file_path = Pathname.new(File.expand_path(tp.path))

          # Only include Ivar::Checked if the class is defined within the project root
          if file_path.to_s.start_with?(root_pathname.to_s)
            # Get the class or module being defined
            klass = tp.self

            # Skip if the class already includes Ivar::Checked
            next if klass.included_modules.include?(Ivar::Checked)

            # Include Ivar::Checked in the class
            klass.include(Ivar::Checked)
          end
        end

        # Enable the trace point
        @trace_point.enable
      end

      if block
        begin
          # Execute the block with auto-checking enabled
          yield
        ensure
          # Disable auto-checking after the block completes
          disable
        end
      end

      # Return nil to avoid returning the trace point
      nil
    end

    # Disables automatic inclusion of Ivar::Checked in classes and modules.
    # @return [void]
    def disable
      @mutex.synchronize do
        if @trace_point
          @trace_point.disable
          @trace_point = nil
        end
      end
    end

    # Returns whether check_all is currently enabled
    # @return [Boolean] true if check_all is enabled, false otherwise
    def enabled?
      @mutex.synchronize { !@trace_point.nil? && @trace_point.enabled? }
    end

    # Returns the current trace point (mainly for testing)
    # @return [TracePoint, nil] The current trace point or nil if not enabled
    def trace_point
      @mutex.synchronize { @trace_point }
    end
  end
end
