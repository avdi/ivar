# frozen_string_literal: true

require "ivar"

class SandwichWithArg
  include Ivar::Checked

  # Pre-declare instance variables to be initialized from positional arguments
  ivar arg: [:@bread, :@cheese]

  def initialize(condiments = [])
    # Note: @bread and @cheese are already set from positional arguments
    # We only need to handle the remaining positional arguments
    @condiments = condiments
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result
  end
end

# Create a sandwich with positional arguments
sandwich = SandwichWithArg.new("wheat", "muenster", ["mayo", "mustard"])

puts sandwich  # Outputs: A wheat sandwich with muenster and mayo, mustard

# Create another sandwich with different positional arguments
sandwich2 = SandwichWithArg.new("rye", "swiss")

puts sandwich2  # Outputs: A rye sandwich with swiss
