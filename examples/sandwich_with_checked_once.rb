# frozen_string_literal: true

require "ivar"

class SandwichWithCheckedOnce
  include Ivar::CheckedOnce

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
    # No need for explicit check_ivars_once call
  end

  def to_s
    result = "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
    result += " and a side of #{@side}" if @side
    result
  end
end

# Create a sandwich - this will automatically check instance variables once
puts "Creating first sandwich..."
SandwichWithCheckedOnce.new

# Create another sandwich - this should not emit warnings
puts "Creating second sandwich..."
SandwichWithCheckedOnce.new
