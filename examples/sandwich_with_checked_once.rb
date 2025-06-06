# frozen_string_literal: true

require "ivar"

class SandwichWithCheckedOnce
  include Ivar::Checked
  ivar_check_policy :warn_once

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = %w[mayo mustard]
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
