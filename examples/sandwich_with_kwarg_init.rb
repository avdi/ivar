# frozen_string_literal: true

require "ivar"

class SandwichWithKwargInit
  include Ivar::Checked

  # Declare instance variables with keyword argument initialization
  # and default values in case they're not provided
  ivar :@bread, init: :kwarg, value: "wheat"
  ivar :@cheese, init: :kwarg, value: "cheddar"

  # Declare condiments with a default value
  ivar :@condiments, value: []

  # Declare pickles with both a default value and kwarg initialization
  ivar :@pickles, value: false, init: :kwarg

  def initialize(extra_condiments: [])
    # The declared variables are already initialized with their values
    # from keyword arguments or defaults
    # Note: bread, cheese, and pickles keywords are "peeled off" and won't be passed to this method
    # But extra_condiments will be passed through

    # Add default condiments (clear first to avoid duplicates)
    @condiments = []
    @condiments << "mayo" unless @pickles
    @condiments << "mustard"

    # Add any extra condiments
    @condiments.concat(extra_condiments)

    # For demonstration, we'll print what keywords were actually received
    received_vars = []
    local_variables.each do |v|
      next if v == :_ || binding.local_variable_get(v).nil?
      received_vars << "#{v}: #{binding.local_variable_get(v).inspect}"
    end
    puts "  Initialize received: #{received_vars.join(", ")}"
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result
  end
end

# Create a sandwich with default values
puts "Default sandwich:"
sandwich = SandwichWithKwargInit.new
puts sandwich
# => "A wheat sandwich with cheddar and mayo, mustard"

# Create a sandwich with custom bread and cheese
puts "\nCustom bread and cheese:"
custom_sandwich = SandwichWithKwargInit.new(bread: "rye", cheese: "swiss")
puts custom_sandwich
# => "A rye sandwich with swiss and mayo, mustard"

# Create a sandwich with pickles
puts "\nSandwich with pickles:"
pickle_sandwich = SandwichWithKwargInit.new(pickles: true)
puts pickle_sandwich
# => "A wheat sandwich with cheddar and mustard with pickles"

# Create a sandwich with extra condiments (not peeled off)
puts "\nSandwich with extra condiments:"
extra_sandwich = SandwichWithKwargInit.new(extra_condiments: ["ketchup", "relish"])
puts extra_sandwich
# => "A wheat sandwich with cheddar and mayo, mustard, ketchup, relish"

# Create a sandwich with both peeled off and passed through kwargs
puts "\nSandwich with both types of kwargs:"
combo_sandwich = SandwichWithKwargInit.new(bread: "sourdough", pickles: true, extra_condiments: ["hot sauce"])
puts combo_sandwich
# => "A sourdough sandwich with cheddar and mustard, hot sauce with pickles"
