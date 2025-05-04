# frozen_string_literal: true

require_relative "test_helper"

class TestCheckAll < Minitest::Test
  def setup
    # Clear the cache to ensure a clean test
    Ivar.clear_analysis_cache
    Ivar.clear_checked_modules if Ivar.respond_to?(:clear_checked_modules)

    # Capture stderr to prevent warnings from appearing in test output
    @original_stderr = $stderr
    $stderr = StringIO.new
  end

  def teardown
    # Restore stderr
    $stderr = @original_stderr
  end

  def test_check_all_applies_to_project_classes
    # Create some test classes
    test_class1 = Class.new do
      def initialize
        @var1 = "value1"
      end

      def method_with_typo
        @typo_veriable = "misspelled"
      end
    end

    test_class2 = Class.new do
      def initialize
        @var2 = "value2"
      end

      def another_method
        @another_typo = "misspelled"
      end
    end

    # Give them names to make debugging easier
    Object.const_set(:TestClass1, test_class1)
    Object.const_set(:TestClass2, test_class2)

    # Force the analysis to be created for both classes
    test_class1_analysis = Ivar::PrismAnalysis.new(test_class1)
    def test_class1_analysis.ivar_references
      [
        {name: :@var1, path: __FILE__, line: 1, column: 1},
        {name: :@typo_veriable, path: __FILE__, line: 2, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[test_class1] = test_class1_analysis

    test_class2_analysis = Ivar::PrismAnalysis.new(test_class2)
    def test_class2_analysis.ivar_references
      [
        {name: :@var2, path: __FILE__, line: 1, column: 1},
        {name: :@another_typo, path: __FILE__, line: 2, column: 1}
      ]
    end
    Ivar.instance_variable_get(:@analysis_cache)[test_class2] = test_class2_analysis

    # Patch the project_file? method to always return true for our test classes
    original_project_file = Ivar.method(:project_file?)
    Ivar.define_singleton_method(:project_file?) do |path, project_root|
      return true if path == __FILE__
      original_project_file.call(path, project_root)
    end

    begin
      # Call check_all
      count = Ivar.check_all

      # Verify that both classes now include Ivar::Validation
      assert_includes test_class1.included_modules, Ivar::Validation
      assert_includes test_class2.included_modules, Ivar::Validation

      # Verify that at least our two test classes were included
      assert count >= 2

      # Create instances and verify that they trigger warnings
      warnings = capture_stderr do
        test_class1.new
        test_class2.new
      end

      # Check that we got warnings about the typos
      assert_match(/unknown instance variable @typo_veriable/, warnings)
      assert_match(/unknown instance variable @another_typo/, warnings)
    ensure
      # Restore the original method
      Ivar.singleton_class.remove_method(:project_file?)
      Ivar.define_singleton_method(:project_file?, original_project_file)
    end
  end

  def test_check_all_skips_core_modules
    # Call check_all
    Ivar.check_all

    # Verify that core modules were not modified
    refute_includes Object.included_modules, Ivar::Validation
    refute_includes String.included_modules, Ivar::Validation
    refute_includes Array.included_modules, Ivar::Validation
  end

  def test_check_all_skips_already_checked_modules
    # Create a test class that already includes Ivar::Validation
    test_class = Class.new do
      include Ivar::Validation

      def initialize
        @var = "value"
      end
    end

    # Give it a name to make debugging easier
    Object.const_set(:TestClassWithValidation, test_class)

    # Verify that the class already includes Ivar::Validation
    assert_includes test_class.included_modules, Ivar::Validation

    # Call check_all
    Ivar.check_all

    # Verify that the class still includes Ivar::Validation
    # (This is just to confirm that check_all didn't break anything)
    assert_includes test_class.included_modules, Ivar::Validation
  end

  private

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
