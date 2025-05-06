# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/ivar/targeted_prism_analysis"
require_relative "fixtures/targeted_analysis/split_target_class"
require_relative "fixtures/targeted_analysis/multi_class_file"
require_relative "fixtures/targeted_analysis/mixed_methods_class"

class TestTargetedPrismAnalysis < Minitest::Test
  def test_split_class_analysis
    analysis = Ivar::TargetedPrismAnalysis.new(SplitTargetClass)

    # Check that we found all the instance variables
    expected_ivars = %i[@part1_var1 @part1_var2 @part2_var1 @part2_var2 @part2_var3]
    assert_equal expected_ivars, analysis.ivars

    # Check that we have the correct number of references
    references = analysis.ivar_references
    assert_equal 12, references.size

    # Check that each reference has the expected fields
    references.each do |ref|
      assert_includes ref, :name
      assert_includes ref, :path
      assert_includes ref, :line
      assert_includes ref, :column
      assert_includes ref, :method
    end

    # Check references for part1_method
    part1_refs = references.select { |ref| ref[:method] == :part1_method }
    assert_equal 4, part1_refs.size

    # Check references for part2_method
    part2_refs = references.select { |ref| ref[:method] == :part2_method }
    assert_equal 4, part2_refs.size

    # Check references for another_part2_method
    another_part2_refs = references.select { |ref| ref[:method] == :another_part2_method }
    assert_equal 2, another_part2_refs.size
    assert_equal :@part2_var3, another_part2_refs.first[:name]
  end

  def test_multi_class_file_analysis
    # Test FirstClass
    first_analysis = Ivar::TargetedPrismAnalysis.new(FirstClass)

    # Check that we found all the instance variables
    expected_first_ivars = %i[@first_var1 @first_var2]
    assert_equal expected_first_ivars, first_analysis.ivars

    # Check references for first_method
    first_refs = first_analysis.ivar_references.select { |ref| ref[:method] == :first_method }
    assert_equal 3, first_refs.size

    # Test SecondClass
    second_analysis = Ivar::TargetedPrismAnalysis.new(SecondClass)

    # Check that we found all the instance variables
    expected_second_ivars = %i[@second_var1 @second_var2]
    assert_equal expected_second_ivars, second_analysis.ivars

    # Check references for second_method
    second_refs = second_analysis.ivar_references.select { |ref| ref[:method] == :second_method }
    assert_equal 3, second_refs.size

    # Ensure no cross-contamination between classes
    first_analysis.ivar_references.each do |ref|
      refute_match(/second_var/, ref[:name].to_s)
    end

    second_analysis.ivar_references.each do |ref|
      refute_match(/first_var/, ref[:name].to_s)
    end
  end

  def test_mixed_methods_class_analysis
    analysis = Ivar::TargetedPrismAnalysis.new(MixedMethodsClass)

    # Check that we found only instance method variables (not class method variables)
    expected_ivars = %i[@instance_var1 @instance_var2 @instance_var3 @private_var]
    assert_equal expected_ivars, analysis.ivars

    # Check that we have the correct number of references
    references = analysis.ivar_references
    assert_equal 10, references.size

    # Check that we don't have any class method variables
    references.each do |ref|
      refute_match(/class_var/, ref[:name].to_s)
      refute_match(/class_method_var/, ref[:name].to_s)
      refute_match(/another_class_var/, ref[:name].to_s)
      refute_match(/class_instance_var/, ref[:name].to_s)
    end

    # Check references for instance_method
    instance_method_refs = references.select { |ref| ref[:method] == :instance_method }
    assert_equal 5, instance_method_refs.size

    # Check references for private_instance_method
    private_method_refs = references.select { |ref| ref[:method] == :private_instance_method }
    assert_equal 3, private_method_refs.size
    assert_includes private_method_refs.map { |ref| ref[:name] }, :@private_var
    assert_includes private_method_refs.map { |ref| ref[:name] }, :@instance_var1
  end
end
