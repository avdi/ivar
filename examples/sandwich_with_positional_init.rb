# frozen_string_literal: true

require "ivar"

class SandwichWithPositionalInit
  include Ivar::Checked

  # Declare instance variables with positional argument initialization
  # and default values in case they're not provided
  ivar :@bread, init: :positional, value: "wheat"
  ivar :@cheese, init: :positional, value: "cheddar"

  # Declare condiments with a default value
  ivar :@condiments, value: []

  # Declare pickles with both a default value and positional initialization
  ivar :@pickles, value: false, init: :positional

  # Note: Don't define parameters for the peeled-off positional arguments
  def initialize(extra_condiments = [])
    # The declared variables are already initialized with their values
    # from positional arguments or defaults
    @condiments += extra_condiments unless extra_condiments.empty?

    # We can also check if pickles were requested and adjust condiments
    @condiments.delete("mayo") if @pickles
  end

  def to_s
    result = "#{@bread} sandwich with #{@cheese} cheese"
    result += " and pickles" if @pickles
    result += ", condiments: #{@condiments.join(", ")}" unless @condiments.empty?
    result
  end
end

# Create a sandwich with all positional arguments
sandwich1 = SandwichWithPositionalInit.new("rye", "swiss", true, ["mustard"])
puts "Sandwich 1: #{sandwich1}"
# => "Sandwich 1: rye sandwich with swiss cheese and pickles, condiments: mustard"

# Create a sandwich with some positional arguments
sandwich2 = SandwichWithPositionalInit.new("sourdough", "provolone", ["mayo", "mustard"])
puts "Sandwich 2: #{sandwich2}"
# => "Sandwich 2: sourdough sandwich with provolone cheese, condiments: mayo, mustard"

# Create a sandwich with default values
sandwich3 = SandwichWithPositionalInit.new
puts "Sandwich 3: #{sandwich3}"
# => "Sandwich 3: wheat sandwich with cheddar cheese"
