# frozen_string_literal: true

require "ivar"

class SandwichWithIvarBlock
  include Ivar::Checked

  # Declare instance variables
  ivar :@side

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @pickles = true
    @condiments = []
    @condiments << "mayo" if !@pickles
    @condiments << "mustard"
    # Note: @side is not set here and remains undefined
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if defined?(@side) && @side
    result
  end

  def add_side(side)
    @side = side
  end
end

# Create a sandwich - this will automatically check instance variables
sandwich = SandwichWithIvarBlock.new
puts sandwich

# Add a side
sandwich.add_side("chips")
puts sandwich
