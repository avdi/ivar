# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich_with_checked_once"

class TestCheckedOnceIntegration < Minitest::Test
  def setup
    Ivar.clear_analysis_cache
  end

  def test_sandwich_with_checked_once
    warnings = capture_stderr do
      SandwichWithCheckedOnce.new
    end

    assert_match(/unknown instance variable @chese/, warnings)
    refute_match(/unknown instance variable @bread/, warnings)
    refute_match(/unknown instance variable @cheese/, warnings)
    refute_match(/unknown instance variable @condiments/, warnings)
  end

  def test_checked_once_only_warns_once
    first_warnings = capture_stderr do
      SandwichWithCheckedOnce.new
    end

    second_warnings = capture_stderr do
      SandwichWithCheckedOnce.new
    end

    assert_match(/unknown instance variable @chese/, first_warnings)
    assert_empty second_warnings
  end
end
