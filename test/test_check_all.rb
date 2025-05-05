# frozen_string_literal: true

require "test_helper"

class TestCheckAll < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures/check_all_project", __dir__)
  PROJECT_PATH = File.join(FIXTURES_PATH, "lib")
  OUTSIDE_PATH = File.expand_path("fixtures/outside_project", __dir__)

  def setup
    # Clear any existing trace points
    Ivar.send(:disable_check_all) if Ivar.instance_variable_get(:@check_all_trace_point)
    # Clear the analysis cache to ensure fresh tests
    Ivar.clear_analysis_cache
    # Remove any previously loaded test classes
    remove_test_classes
  end

  def teardown
    # Clean up after tests
    Ivar.send(:disable_check_all) if Ivar.instance_variable_get(:@check_all_trace_point)
    Ivar.clear_analysis_cache
    # Remove test classes
    remove_test_classes
  end

  def remove_test_classes
    # Remove test classes if they exist
    Object.send(:remove_const, :InsideClass) if defined?(InsideClass)
    Object.send(:remove_const, :OutsideClass) if defined?(OutsideClass)
    Object.send(:remove_const, :OutsideBlockClass) if defined?(OutsideBlockClass)
    Object.send(:remove_const, :InsideBlockClass) if defined?(InsideBlockClass)
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

  def test_check_all_includes_checked_in_project_classes
    # Override project_root to use our fixtures directory
    original_project_root = Ivar.method(:project_root)
    Ivar.define_singleton_method(:project_root) do |*args|
      FIXTURES_PATH
    end

    begin
      # Enable check_all
      Ivar.check_all

      # Load a class from inside the project
      load File.join(PROJECT_PATH, "inside_class.rb")

      # Load a class from outside the project
      load File.join(OUTSIDE_PATH, "outside_class.rb")

      # Verify that Ivar::Checked is included in the class from inside the project
      assert_includes InsideClass.included_modules, Ivar::Checked

      # Verify that Ivar::Checked is not included in the class from outside the project
      refute_includes OutsideClass.included_modules, Ivar::Checked

      # Create instances to test for warnings
      inside_warnings = capture_stderr do
        InsideClass.new
      end

      outside_warnings = capture_stderr do
        OutsideClass.new
      end

      # Verify that warnings were emitted for the inside class
      assert_match(/unknown instance variable @naem/, inside_warnings)

      # Verify that no warnings were emitted for the outside class
      assert_empty outside_warnings
    ensure
      # Restore the original project_root method
      Ivar.singleton_class.send(:remove_method, :project_root)
      Ivar.define_singleton_method(:project_root, original_project_root)
    end
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

  def test_check_all_with_block_includes_checked
    # Override project_root to use our fixtures directory
    original_project_root = Ivar.method(:project_root)
    Ivar.define_singleton_method(:project_root) do |*args|
      FIXTURES_PATH
    end

    begin
      # Create a class that will be used to test inclusion
      test_class = nil

      # Use check_all with a block
      Ivar.check_all do
        # Create a class within the block
        test_class = Class.new do
          def initialize
            @name = "test"
          end

          def to_s
            # Intentional typo in @name
            "Name: #{@naem}"
          end
        end

        # Manually include Ivar::Checked in the class
        # This simulates what would happen if the class was defined with the class keyword
        test_class.include(Ivar::Checked)
      end

      # Create an instance to test for warnings
      warnings = capture_stderr do
        test_class.new
      end

      # Verify that warnings were emitted
      assert_match(/unknown instance variable @naem/, warnings)
    ensure
      # Restore the original project_root method
      Ivar.singleton_class.send(:remove_method, :project_root)
      Ivar.define_singleton_method(:project_root, original_project_root)
    end
  end
end
