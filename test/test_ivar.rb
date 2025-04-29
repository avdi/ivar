# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class TestIvar < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ivar::VERSION
  end

  def test_ivar_tools_warns_about_unknown_ivars
    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Load the fixture file
    require_relative "fixtures/sandwich_with_ivar_tools"

    # Create an instance and call to_s to trigger the warning
    sandwich = SandwichWithIvarTools.new
    sandwich.to_s

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chese/, warnings)
    assert_match(/Did you mean: @cheese\?/, warnings)
  end

  def test_checked_ivars_warns_about_unknown_ivars
    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Load the fixture file
    require_relative "fixtures/sandwich_with_checked_ivars"

    # Create an instance and call to_s to trigger the warning
    sandwich = SandwichWithCheckedIvars.new
    sandwich.to_s

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chese/, warnings)
    assert_match(/Did you mean: @cheese\?/, warnings)
  end
end
