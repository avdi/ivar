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
      disable if @trace_point
      root_pathname = Pathname.new(project_root)
      @mutex.synchronize do
        # :end means "end of module or class definition" in TracePoint
        @trace_point = TracePoint.new(:end) do |tp|
          next unless tp.path
          file_path = Pathname.new(File.expand_path(tp.path))
          if file_path.to_s.start_with?(root_pathname.to_s)
            klass = tp.self
            next if klass.included_modules.include?(Ivar::Checked)
            klass.include(Ivar::Checked)
          end
        end

        @trace_point.enable
      end

      if block
        begin
          yield
        ensure
          disable
        end
      end

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
