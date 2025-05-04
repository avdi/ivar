# frozen_string_literal: true

require "ivar"

class SandwichWithInitialValues
  include Ivar::Checked

  # Declare instance variables with initial values
  ivar ":@bread": "wheat",
    ":@cheese": "muenster",
    ":@condiments": ["mayo", "mustard"],
    ":@pickles": true

  # Declare a variable without an initial value
  ivar :@side

  def initialize(extra_condiments = [])
    # The declared variables are already initialized with their values
    # We can modify them here
    @condiments += extra_condiments unless extra_condiments.empty?

    # We can also check if pickles were requested and adjust condiments
    @condiments.delete("mayo") if @pickles
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

# Create a sandwich with default values
sandwich = SandwichWithInitialValues.new
puts sandwich
# => "A wheat sandwich with muenster and mustard with pickles"

# Create a sandwich with extra condiments
sandwich_with_extras = SandwichWithInitialValues.new(["ketchup", "relish"])
puts sandwich_with_extras
# => "A wheat sandwich with muenster and mustard, ketchup, relish with pickles"

# Add a side
sandwich.add_side("chips")
puts sandwich
# => "A wheat sandwich with muenster and mustard with pickles and a side of chips"
