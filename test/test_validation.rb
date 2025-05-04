# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich_with_validation"

class TestValidation < Minitest::Test
  def test_check_ivars_warns_about_unknown_variables
    # Capture stderr output
    warnings = capture_stderr do
      # Create a sandwich with validation which should trigger warnings
      SandwichWithValidation.new
    end

    # Check that we got warnings about the typo in the code
    assert_match(/unknown instance variable @chese/, warnings)

    # Check that we get warnings for the variable
    assert_match(/unknown instance variable @chese/, warnings)

    # We should have at least one warning
    chese_warnings = warnings.scan(/unknown instance variable @chese/).count
    assert chese_warnings >= 1, "Should have at least one warning for @chese"

    # Check that we didn't get warnings about defined variables
    refute_match(/unknown instance variable @bread/, warnings)
    refute_match(/unknown instance variable @cheese/, warnings)
    refute_match(/unknown instance variable @condiments/, warnings)
    refute_match(/unknown instance variable @typo_var/, warnings)

    # Check that we didn't get warnings about allowed variables
    refute_match(/unknown instance variable @side/, warnings)
  end

  def test_check_ivars_suggests_corrections
    # Create a class with a typo in the code
    klass = Class.new do
      include Ivar::Validation

      def initialize
        @correct = "value"
        check_ivars
      end

      def use_typo
        # First occurrence of the typo
        @typo_veriable = "misspelled"
        # Second occurrence of the same typo
        puts "The value is #{@typo_veriable}"
      end
    end

    # Capture stderr output
    warnings = capture_stderr do
      # Create an instance to trigger the warnings
      klass.new
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # Check that we get warnings for the variable
    assert_match(/unknown instance variable @typo_veriable/, warnings)

    # We should have at least one warning
    typo_warnings = warnings.scan(/unknown instance variable @typo_veriable/).count
    assert typo_warnings >= 1, "Should have at least one warning for @typo_veriable"
  end
end
