# frozen_string_literal: true

require "ivar"

class SandwichWithBlockValues
  include Ivar::Checked

  # Declare condiments with a block that generates default values based on the variable name
  ivar(:@mayo, :@mustard, :@ketchup) { |varname| !varname.include?("mayo") }

  # Declare bread and cheese with individual values
  ivar "@bread": "wheat", "@cheese": "cheddar"

  # Declare a variable without an initial value
  ivar :@side

  def initialize(options = {})
    # Override any condiments based on options
    @mayo = true if options[:add_mayo]
    @mustard = false if options[:no_mustard]
    @ketchup = false if options[:no_ketchup]

    # Set the side if provided
    @side = options[:side] if options[:side]
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"

    condiments = []
    condiments << "mayo" if @mayo
    condiments << "mustard" if @mustard
    condiments << "ketchup" if @ketchup

    result += " with #{condiments.join(", ")}" unless condiments.empty?
    result += " and a side of #{@side}" if defined?(@side) && @side
    result
  end
end

# Create a sandwich with default values (no mayo, but has mustard and ketchup)
sandwich = SandwichWithBlockValues.new
puts sandwich
# => "A wheat sandwich with cheddar with mustard, ketchup"

# Create a sandwich with mayo added
sandwich_with_mayo = SandwichWithBlockValues.new(add_mayo: true)
puts sandwich_with_mayo
# => "A wheat sandwich with cheddar with mayo, mustard, ketchup"

# Create a sandwich with a side
sandwich_with_side = SandwichWithBlockValues.new(side: "chips")
puts sandwich_with_side
# => "A wheat sandwich with cheddar with mustard, ketchup and a side of chips"
