# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich_with_checked_ivars"
require_relative "fixtures/parent_with_checked_ivars"
require_relative "fixtures/child_with_checked_ivars"

class TestCheckedIntegration < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_sandwich_with_checked_ivars
    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create a sandwich with Checked which should trigger warnings
    SandwichWithCheckedIvars.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings about the typo in the code
    assert_match(/unknown instance variable @chese/, warnings)

    # Check that we didn't get warnings about defined variables
    refute_match(/unknown instance variable @bread/, warnings)
    refute_match(/unknown instance variable @cheese/, warnings)
    refute_match(/unknown instance variable @condiments/, warnings)
  end

  def test_parent_child_with_checked_ivars
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache

    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create a child instance which should trigger warnings
    ChildWithCheckedIvars.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings about the typo in the child class
    assert_match(/unknown instance variable @chyld_var3/, warnings)
  end

  def test_checked_only_warns_once_per_class
    # Capture stderr output for first instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create first sandwich instance
    SandwichWithCheckedIvars.new

    # Get the captured warnings
    first_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Capture stderr output for second instance
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create second sandwich instance
    SandwichWithCheckedIvars.new

    # Get the captured warnings
    second_warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @chese/, first_warnings)

    # Check that we didn't get warnings for the second instance
    assert_empty second_warnings
  end
end
