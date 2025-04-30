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

  def setup_analysis_cache
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
  end

  def test_get_analysis_returns_prism_analysis
    setup_analysis_cache
    analysis = Ivar.get_analysis(Sandwich)
    assert_instance_of Ivar::PrismAnalysis, analysis
    assert_equal %i[@bread @cheese @chese @condiments @side], analysis.ivars
  end

  def test_get_analysis_caches_results
    setup_analysis_cache
    # First call should create a new analysis
    first_analysis = Ivar.get_analysis(Sandwich)

    # Second call should return the cached analysis (same object)
    second_analysis = Ivar.get_analysis(Sandwich)
    assert_equal first_analysis.object_id, second_analysis.object_id
  end

  def test_get_analysis_creates_separate_cache_entries_for_different_classes
    setup_analysis_cache
    sandwich_analysis = Ivar.get_analysis(Sandwich)
    split_class_analysis = Ivar.get_analysis(SplitClass)

    # Different classes should have different analyses
    refute_equal sandwich_analysis.object_id, split_class_analysis.object_id

    # Each class should have the correct ivars
    assert_equal %i[@bread @cheese @chese @condiments @side], sandwich_analysis.ivars
    assert_equal %i[@part1_var1 @part1_var2 @part2_var1 @part2_var2 @part2_var3], split_class_analysis.ivars

    # Calling again with the same class should return the cached analysis
    second_split_class_analysis = Ivar.get_analysis(SplitClass)
    assert_equal split_class_analysis.object_id, second_split_class_analysis.object_id
  end
end
