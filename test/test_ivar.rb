# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich"
require_relative "fixtures/split_class"
require_relative "fixtures/sandwich_with_validation"

# These fixtures will be uncommented when the corresponding modules are implemented
# require_relative "fixtures/sandwich_with_ivar_tools"
require_relative "fixtures/sandwich_with_checked_ivars"
# require_relative "fixtures/parent_with_ivar_tools"
# require_relative "fixtures/child_with_ivar_tools"
require_relative "fixtures/parent_with_checked_ivars"
require_relative "fixtures/child_with_checked_ivars"

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
      assert_includes ref, :column
    end

    # Check a few specific references
    bread_refs = references.select { |ref| ref[:name] == :@bread }
    assert_equal 2, bread_refs.size # One in initialize, one in to_s

    # Find the reference to @chese (misspelled)
    chese_ref = references.find { |ref| ref[:name] == :@chese }
    assert_equal :@chese, chese_ref[:name]
    assert chese_ref[:path].end_with?("sandwich.rb")
    assert_equal 12, chese_ref[:line]
    assert_equal 42, chese_ref[:column]
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

  def test_check_ivars_warns_about_unknown_variables
    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create a class that will use validation
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @known_var = "known"
        check_ivars(add: [:@allowed_var])
      end

      def method_with_typo
        # This variable is not defined in initialize, so it should trigger a warning
        @unknown_var = "unknown"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Add the method_with_typo method to the analysis
    def instance.method_with_typo
      @unknown_var = "unknown"
    end

    # Call check_ivars to validate
    instance.check_ivars(add: [:@allowed_var])

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got a warning about the unknown variable
    assert_match(/unknown instance variable @unknown_var/, warnings)

    # Check that we didn't get warnings about known variables
    refute_match(/unknown instance variable @known_var/, warnings)

    # Check that we didn't get warnings about allowed variables
    refute_match(/unknown instance variable @allowed_var/, warnings)
  end

  def test_check_ivars_suggests_corrections
    # Capture stderr output
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create a class with a typo in an instance variable
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
        check_ivars
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    # Create an instance to define the class
    instance = klass.new

    # Add the method_with_typo method to the analysis
    def instance.method_with_typo
      @typo_veriable = "misspelled"
    end

    # Call check_ivars to validate
    instance.check_ivars

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # Check that we get warnings for the variable
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # We should have at least one warning
    typo_warnings = warnings.scan(/unknown instance variable @typo_veriable/).count
    assert typo_warnings >= 1, "Should have at least one warning for @typo_veriable"
  end

  def test_thread_safety_of_analysis_cache
    setup_analysis_cache

    # Create a bunch of test classes
    test_classes = 10.times.map do |i|
      Class.new do
        define_method(:initialize) do
          instance_variable_set(:"@var_#{i}", "value")
        end
      end
    end

    # Run multiple threads that access the cache simultaneously
    threads = 5.times.map do
      Thread.new do
        # Each thread will get analysis for all classes in random order
        test_classes.shuffle.each do |klass|
          analysis = Ivar.get_analysis(klass)
          # Verify the analysis is correct for this class
          assert_instance_of Ivar::PrismAnalysis, analysis
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify each class has an entry in the cache
    test_classes.each do |klass|
      assert Ivar.instance_variable_get(:@analysis_cache).key?(klass)
    end
  end

  def test_thread_safety_of_checked_classes
    setup_analysis_cache

    # Create a bunch of test classes
    test_classes = 10.times.map do |_i|
      Class.new
    end

    # Run multiple threads that mark classes as checked simultaneously
    threads = 5.times.map do
      Thread.new do
        # Each thread will mark all classes in random order
        test_classes.shuffle.each do |klass|
          Ivar.mark_class_checked(klass)
          # Verify the class is marked as checked
          assert Ivar.class_checked?(klass)
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify each class is marked as checked
    test_classes.each do |klass|
      assert Ivar.class_checked?(klass)
    end
  end
end
