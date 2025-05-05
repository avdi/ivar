# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ivar"

# Enable checking for all classes and modules defined in the project
Ivar.check_all

# Now any class or module defined in the project will have Ivar::Checked included
class Sandwich
  # No need to include Ivar::Checked manually

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
  end

  def to_s
    # Intentional typo in @cheese
    "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
  end
end

# Create a sandwich - this will automatically check instance variables
sandwich = Sandwich.new
puts sandwich

# Define another class to demonstrate that it also gets Ivar::Checked
class Drink
  def initialize
    @type = "soda"
    @size = "medium"
  end

  def to_s
    # Intentional typo in @size
    "A #{@sise} #{@type}"
  end
end

# Create a drink - this will also automatically check instance variables
drink = Drink.new
puts drink
