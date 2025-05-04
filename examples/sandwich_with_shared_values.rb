# frozen_string_literal: true

require "ivar"

class SandwichWithSharedValues
  include Ivar::Checked

  # Declare multiple condiments with the same initial value (true)
  ivar :@mayo, :@mustard, :@ketchup, value: true

  # Declare bread and cheese with individual values
  ivar ":@bread": "wheat", ":@cheese": "cheddar"

  # Declare a variable without an initial value
  ivar :@side

  def initialize(options = {})
    # Override any condiments based on options
    @mayo = false if options[:no_mayo]
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

# Create a sandwich with default values (all condiments)
sandwich = SandwichWithSharedValues.new
puts sandwich
# => "A wheat sandwich with cheddar with mayo, mustard, ketchup"

# Create a sandwich with no mayo
sandwich_no_mayo = SandwichWithSharedValues.new(no_mayo: true)
puts sandwich_no_mayo
# => "A wheat sandwich with cheddar with mustard, ketchup"

# Create a sandwich with a side
sandwich_with_side = SandwichWithSharedValues.new(side: "chips")
puts sandwich_with_side
# => "A wheat sandwich with cheddar with mayo, mustard, ketchup and a side of chips"
