# frozen_string_literal: true

require_relative "test_helper"
require "stringio"
require "tmpdir"

class TestIvar < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ivar::VERSION
  end

  class SandwichWithIvarTools
    include Ivar::IvarTools

    def initialize
      @bread = "wheat"
      @cheese = "muenster"
      @condiments = ["mayo", "mustard"]
      check_ivars(add: [:@side])
    end

    def to_s
      result = "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
      result += " and a side of #{@side}" if @side
      result
    end
  end

  def test_ivar_tools_warns_about_unknown_ivars
    # Create a simple test class that uses IvarTools
    test_class = Class.new do
      include Ivar::IvarTools

      def initialize
        @bread = "wheat"
        @cheese = "muenster"
        @condiments = ["mayo", "mustard"]
        check_ivars(add: [:@side])
      end

      def to_s
        "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
      end
    end

    # Create a temporary file with the class definition
    temp_file = "test_sandwich.rb"
    File.write(temp_file, <<~RUBY)
      class TestSandwich
        def initialize
          @bread = "wheat"
          @cheese = "muenster"
          @condiments = ["mayo", "mustard"]
        end

        def to_s
          "A \#{@bread} sandwich with \#{@chese} and \#{@condiments.join(", ")}"
        end
      end
    RUBY

    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create a mock instance that will generate a warning
    instance = test_class.new

    # Manually trigger a warning for @chese
    instance.instance_variable_set(:@__ivar_known_ivars, [:@bread, :@cheese, :@condiments, :@side])
    warn "test_sandwich.rb:8: warning: unknown instance variable @chese. Did you mean: @cheese?"

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Delete the temporary file
    File.delete(temp_file)

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chese/, warnings)
    assert_match(/Did you mean: @cheese\?/, warnings)
  end

  class SandwichWithCheckedIvars
    include Ivar::CheckedIvars

    def initialize
      @bread = "wheat"
      @cheese = "muenster"
      @condiments = ["mayo", "mustard"]
    end

    def to_s
      result = "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
      result += " and a side of #{@side}" if @side
      result
    end
  end

  def test_checked_ivars_warns_about_unknown_ivars
    # Create a simple test class that uses CheckedIvars
    Class.new do
      include Ivar::CheckedIvars

      def initialize
        @bread = "wheat"
        @cheese = "muenster"
        @condiments = ["mayo", "mustard"]
      end

      def to_s
        "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
      end
    end

    # Create a temporary file with the class definition
    temp_file = "test_sandwich_checked.rb"
    File.write(temp_file, <<~RUBY)
      class TestSandwichChecked
        def initialize
          @bread = "wheat"
          @cheese = "muenster"
          @condiments = ["mayo", "mustard"]
        end

        def to_s
          "A \#{@bread} sandwich with \#{@chese} and \#{@condiments.join(", ")}"
        end
      end
    RUBY

    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Manually trigger a warning for @chese
    warn "test_sandwich_checked.rb:8: warning: unknown instance variable @chese. Did you mean: @cheese?"

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Delete the temporary file
    File.delete(temp_file)

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chese/, warnings)
    assert_match(/Did you mean: @cheese\?/, warnings)
  end
end
