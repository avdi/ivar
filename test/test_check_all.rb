# frozen_string_literal: true

require "test_helper"
require "open3"

class TestCheckAll < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/check_all_project", __dir__)

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

  def test_check_all_with_block_scope
    # Use check_all with a block
    Ivar.check_all do
      # Verify that check_all is enabled within the block
      trace_point = Ivar.instance_variable_get(:@check_all_trace_point)
      refute_nil trace_point
      assert trace_point.enabled?
    end

    # Verify that check_all is disabled after the block
    assert_nil Ivar.instance_variable_get(:@check_all_trace_point)
  end

  def test_check_all_includes_checked_in_project_classes
    # Run the test in a subprocess
    script_path = File.join(FIXTURES_PATH, "test_inside_class.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path)

    # Verify that the script ran successfully
    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"

    # Verify that the expected success messages were output
    assert_includes stdout, "SUCCESS: InsideClass includes Ivar::Checked"
    assert_includes stdout, "SUCCESS: Warning emitted for unknown instance variable @naem"
  end

  def test_check_all_excludes_outside_classes
    # Run the test in a subprocess
    script_path = File.join(FIXTURES_PATH, "test_outside_class.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path)

    # Verify that the script ran successfully
    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"

    # Verify that the expected success messages were output
    assert_includes stdout, "SUCCESS: OutsideClass does not include Ivar::Checked"
    assert_includes stdout, "SUCCESS: No warnings emitted for OutsideClass"
  end

  def test_check_all_with_block_scope_in_subprocess
    # Run the test in a subprocess
    script_path = File.join(FIXTURES_PATH, "test_block_scope.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path)

    # Verify that the script ran successfully
    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"

    # Verify that the expected success messages were output
    assert_includes stdout, "SUCCESS: BeforeClass does not include Ivar::Checked before block"
    assert_includes stdout, "SUCCESS: WithinBlockClass includes Ivar::Checked within block"
    assert_includes stdout, "SUCCESS: Warning emitted for unknown instance variable @naem in WithinBlockClass"
    assert_includes stdout, "SUCCESS: AfterClass does not include Ivar::Checked after block"
    assert_includes stdout, "SUCCESS: No warnings emitted for BeforeClass and AfterClass"
  end
end
