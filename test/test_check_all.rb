# frozen_string_literal: true

require "test_helper"
require "open3"

class TestCheckAll < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/check_all_project", __dir__)

  def setup
    Ivar.send(:disable_check_all)
    Ivar.clear_analysis_cache
  end

  def teardown
    Ivar.send(:disable_check_all)
    Ivar.clear_analysis_cache
  end

  def test_check_all_enables_trace_point
    Ivar.check_all
    manager = Ivar::CHECK_ALL_MANAGER

    trace_point = manager.trace_point
    refute_nil trace_point
    assert trace_point.enabled?
  end

  def test_disable_check_all
    Ivar.check_all
    manager = Ivar::CHECK_ALL_MANAGER

    refute_nil manager.trace_point
    assert manager.enabled?

    Ivar.send(:disable_check_all)

    assert_nil manager.trace_point
    refute manager.enabled?
  end

  def test_check_all_with_block_scope
    Ivar.check_all do
      manager = Ivar::CHECK_ALL_MANAGER
      trace_point = manager.trace_point
      refute_nil trace_point
      assert trace_point.enabled?
    end

    manager = Ivar::CHECK_ALL_MANAGER
    assert_nil manager.trace_point
    refute manager.enabled?
  end

  def test_check_all_includes_checked_in_project_classes
    script_path = File.join(FIXTURES_PATH, "test_inside_class.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path)

    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"
    assert_includes stdout, "SUCCESS: InsideClass includes Ivar::Checked"
    assert_includes stdout, "SUCCESS: Warning emitted for unknown instance variable @naem"
  end

  def test_check_all_excludes_outside_classes
    script_path = File.join(FIXTURES_PATH, "test_outside_class.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path)

    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"
    assert_includes stdout, "SUCCESS: OutsideClass does not include Ivar::Checked"
    assert_includes stdout, "SUCCESS: No warnings emitted for OutsideClass"
  end

  def test_check_all_with_block_scope_in_subprocess
    script_path = File.join(FIXTURES_PATH, "test_block_scope.rb")
    stdout, stderr, status = Open3.capture3("ruby", script_path, chdir: FIXTURES_PATH)

    pp(status:, stdout:, stderr:)

    assert_equal 0, status.exitstatus, "Script failed with: #{stderr}"
    assert_match(/warning.*unknown instance variable @withinclass_naem/, stderr)
  end
end
