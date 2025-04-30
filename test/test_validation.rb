# frozen_string_literal: true

require_relative "test_helper"
require_relative "fixtures/sandwich_with_validation"
require "stringio"

class TestValidation < Minitest::Test
  def test_check_ivars_warns_about_unknown_variables
    # Capture stderr output
    stderr_output = capture_stderr do
      # Create a sandwich with validation which should trigger warnings
      SandwichWithValidation.new
    end

    # Check that we got a warning about the typo in the code
    assert_match(/unknown instance variable @chese/, stderr_output)

    # Check that we didn't get warnings about defined variables
    refute_match(/unknown instance variable @bread/, stderr_output)
    refute_match(/unknown instance variable @cheese/, stderr_output)
    refute_match(/unknown instance variable @condiments/, stderr_output)
    refute_match(/unknown instance variable @typo_var/, stderr_output)

    # Check that we didn't get warnings about allowed variables
    refute_match(/unknown instance variable @side/, stderr_output)
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
        @typo_veriable = "misspelled"
      end
    end

    # Capture warnings during object creation
    output = capture_stderr do
      klass.new
    end

    # Check that we got a warning about the typo
    assert_match(/unknown instance variable @typo_veriable/, output)
  end

  private

  # Helper method to capture stderr output
  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
