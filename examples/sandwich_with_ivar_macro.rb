# frozen_string_literal: true

require "ivar"

class SandwichWithIvarMacro
  include Ivar::Checked

  # Declare instance variables that might be referenced before being set
  # You don't need to include variables that are always set in initialize
  ivar :@side

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = %w[mayo mustard]
    # NOTE: @side is not set here and remains undefined
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}"
    # This won't trigger a warning because @side is declared
    # We need to check if it's defined first
    result += " and a side of #{@side}" if defined?(@side) && @side
    result
  end

  def add_side(side)
    @side = side
  end
end

# Create a sandwich - this will automatically check instance variables
sandwich = SandwichWithIvarMacro.new
puts sandwich

# Add a side and print again
sandwich.add_side("chips")
puts sandwich
