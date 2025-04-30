# frozen_string_literal: true

require "ivar"

class SandwichWithIvarBlock
  include Ivar::Checked

  # Pre-declare instance variables with a block that runs before initialization
  ivar :@side do
    @pickles = true
    @condiments = []
  end

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    # Note: @pickles is already set to true by the ivar block
    # Note: @condiments is already initialized to an empty array by the ivar block
    @condiments << "mayo" if !@pickles
    @condiments << "mustard"
    # Note: @side is not set here, but it's pre-initialized to nil
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if @side
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
