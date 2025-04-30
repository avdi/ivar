# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich"
require_relative "fixtures/split_class"
require "stringio"

# These fixtures will be uncommented when the corresponding modules are implemented
# require_relative "fixtures/sandwich_with_ivar_tools"
# require_relative "fixtures/sandwich_with_checked_ivars"
# require_relative "fixtures/parent_with_ivar_tools"
# require_relative "fixtures/child_with_ivar_tools"
# require_relative "fixtures/parent_with_checked_ivars"
# require_relative "fixtures/child_with_checked_ivars"

class TestIvar < Minitest::Test
  def test_ivar_analysis
    analysis = Ivar::PrismAnalysis.new(Sandwich)
    assert_equal %i[@bread @cheese @chese @condiments @side], analysis.ivars
  end

  def test_ivar_analysis_with_split_class
    analysis = Ivar::PrismAnalysis.new(SplitClass)
    expected_ivars = %i[@part1_var1 @part1_var2 @part2_var1 @part2_var2 @part2_var3]
    assert_equal expected_ivars, analysis.ivars
  end

  def test_ivar_references
    analysis = Ivar::PrismAnalysis.new(Sandwich)
    references = analysis.ivar_references

    # Check that we have the expected number of references
    assert_equal 8, references.size

    # Check that each reference has the expected keys
    references.each do |ref|
      assert_includes ref, :name
      assert_includes ref, :path
      assert_includes ref, :line
      assert_includes ref, :column if ref.key?(:column)
    end

    # Check a few specific references
    bread_refs = references.select { |ref| ref[:name] == :@bread }
    assert_equal 2, bread_refs.size # One in initialize, one in to_s

    # Find the reference to @chese (misspelled)
    chese_ref = references.find { |ref| ref[:name] == :@chese }
    assert_equal :@chese, chese_ref[:name]
    assert chese_ref[:path].end_with?("sandwich.rb")
    assert_equal 12, chese_ref[:line]
  end

  # Tests for inheritance will be added here when implemented
end
