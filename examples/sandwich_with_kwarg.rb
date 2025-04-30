# frozen_string_literal: true

require "ivar"

class SandwichWithKwarg
  include Ivar::Checked

  # Pre-declare instance variables to be initialized from keyword arguments
  ivar kwarg: [:@bread, :@cheese, :@condiments]

  def initialize(pickles: false, side: nil)
    # Note: @bread, @cheese, and @condiments are already set from keyword arguments
    # We only need to handle the remaining keyword arguments
    @pickles = pickles
    @side = side
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if @side
    result
  end
end

# Create a sandwich with keyword arguments
sandwich = SandwichWithKwarg.new(
  bread: "wheat",
  cheese: "muenster",
  condiments: ["mayo", "mustard"],
  side: "chips"
)

puts sandwich  # Outputs: A wheat sandwich with muenster and mayo, mustard and a side of chips

# Create another sandwich with different keyword arguments
sandwich2 = SandwichWithKwarg.new(
  bread: "rye",
  cheese: "swiss",
  condiments: ["mustard"],
  pickles: true
)

puts sandwich2  # Outputs: A rye sandwich with swiss and mustard with pickles
