# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich_with_checked_once"

class TestCheckedOnceIntegration < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_sandwich_with_checked_once
    # Capture stderr output
    warnings = capture_stderr do
      # Create a sandwich with Checked and warn_once policy which should trigger warnings
      SandwichWithCheckedOnce.new
    end

    # Check that we got warnings about the typo in the code
    assert_match(/unknown instance variable @chese/, warnings)

    # Check that we didn't get warnings about defined variables
    refute_match(/unknown instance variable @bread/, warnings)
    refute_match(/unknown instance variable @cheese/, warnings)
    refute_match(/unknown instance variable @condiments/, warnings)
  end

  def test_checked_once_only_warns_once
    # Capture stderr output for first instance
    first_warnings = capture_stderr do
      # Create first sandwich instance
      SandwichWithCheckedOnce.new
    end

    # Capture stderr output for second instance
    second_warnings = capture_stderr do
      # Create second sandwich instance
      SandwichWithCheckedOnce.new
    end

    # Check that we got warnings for the first instance
    assert_match(/unknown instance variable @chese/, first_warnings)

    # Check that we didn't get warnings for the second instance
    assert_empty second_warnings
  end
end
