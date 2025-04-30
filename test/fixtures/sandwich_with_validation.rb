# frozen_string_literal: true

require "ivar"

class SandwichWithValidation
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = %w[mayo mustard]
    # This variable is not in the analysis because it's not referenced elsewhere
    @typo_var = "should trigger warning"
    check_ivars(add: [:@side])
  end

  def to_s
    result = "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
    result += " and a side of #{@side}" if @side
    result
  end
end
