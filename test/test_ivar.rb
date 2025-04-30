# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich"

class TestIvar < Minitest::Test
  def test_ivar_analysis
    analysis = Ivar::PrismAnalysis.new(Sandwich)
    assert_equal %i[@bread @cheese @chese @condiments @side], analysis.ivars
  end
end
