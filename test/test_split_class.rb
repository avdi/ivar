# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/split_class"

class TestSplitClass < Minitest::Test
  def test_ivar_analysis_with_split_class
    analysis = Ivar::PrismAnalysis.new(SplitClass)
    expected_ivars = %i[@part1_var1 @part1_var2 @part2_var1 @part2_var2 @part2_var3]
    assert_equal expected_ivars, analysis.ivars
  end
end
