# frozen_string_literal: true

require "ivar"

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
