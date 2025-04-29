# frozen_string_literal: true

require "ivar"

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
