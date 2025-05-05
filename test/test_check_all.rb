# frozen_string_literal: true

require "test_helper"

class TestCheckAll < Minitest::Test
  def setup
    # Clear any existing trace points
    Ivar.send(:disable_check_all) if Ivar.instance_variable_get(:@check_all_trace_point)
    # Clear the analysis cache to ensure fresh tests
    Ivar.clear_analysis_cache
  end

  def teardown
    # Clean up after tests
    Ivar.send(:disable_check_all) if Ivar.instance_variable_get(:@check_all_trace_point)
    Ivar.clear_analysis_cache
  end

  def test_check_all_enables_trace_point
    # Enable check_all
    Ivar.check_all

    # Verify that a trace point is created and enabled
    trace_point = Ivar.instance_variable_get(:@check_all_trace_point)
    refute_nil trace_point
    assert trace_point.enabled?
  end

  def test_disable_check_all
    # Enable check_all
    Ivar.check_all

    # Verify that check_all is enabled
    refute_nil Ivar.instance_variable_get(:@check_all_trace_point)

    # Disable check_all
    Ivar.send(:disable_check_all)

    # Verify that check_all is disabled
    assert_nil Ivar.instance_variable_get(:@check_all_trace_point)
  end

  def test_check_all_with_block_disables_after_block
    # Use check_all with a block
    Ivar.check_all do
      # Verify that check_all is enabled within the block
      refute_nil Ivar.instance_variable_get(:@check_all_trace_point)
    end

    # Verify that check_all is disabled after the block
    assert_nil Ivar.instance_variable_get(:@check_all_trace_point)
  end

  def test_check_all_trace_point_logic
    # Mock the project root to be a specific directory
    original_project_root = Ivar.method(:project_root)
    Ivar.define_singleton_method(:project_root) do |*args|
      "/fake/project/root"
    end

    begin
      # We'll create classes in the mock objects

      # Create mock TracePoint objects for testing
      mock_tp_inside = Object.new
      def mock_tp_inside.path
        "/fake/project/root/lib/my_class.rb"
      end

      def mock_tp_inside.self
        @self_class ||= Class.new
      end

      mock_tp_outside = Object.new
      def mock_tp_outside.path
        "/some/other/path/lib/external_class.rb"
      end

      def mock_tp_outside.self
        @self_class ||= Class.new
      end

      # Create a trace point with our test logic
      trace_proc = nil

      # Override TracePoint.new to capture the proc
      original_trace_point_new = TracePoint.method(:new)
      TracePoint.define_singleton_method(:new) do |*args, &block|
        trace_proc = block
        Object.new.tap do |obj|
          def obj.enable
          end

          def obj.disable
          end

          def obj.enabled?
            true
          end
        end
      end

      begin
        # Enable check_all to create our trace point
        Ivar.check_all

        # Verify we captured the proc
        refute_nil trace_proc

        # Manually call the trace proc with our mock TracePoint for inside the project
        trace_proc.call(mock_tp_inside)

        # Verify that Ivar::Checked would be included for files inside the project
        assert_includes mock_tp_inside.self.included_modules, Ivar::Checked

        # Manually call the trace proc with our mock TracePoint for outside the project
        trace_proc.call(mock_tp_outside)

        # Verify that Ivar::Checked would not be included for files outside the project
        refute_includes mock_tp_outside.self.included_modules, Ivar::Checked
      ensure
        # Restore the original TracePoint.new method
        TracePoint.singleton_class.send(:remove_method, :new)
        TracePoint.define_singleton_method(:new, original_trace_point_new)
      end
    ensure
      # Restore the original project_root method
      Ivar.singleton_class.send(:remove_method, :project_root)
      Ivar.define_singleton_method(:project_root, original_project_root)
    end
  end
end
