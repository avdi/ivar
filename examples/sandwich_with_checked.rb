# frozen_string_literal: true

require "ivar"

class SandwichWithChecked
  include Ivar::Checked

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

# Create a sandwich - this will automatically check instance variables
SandwichWithChecked.new
