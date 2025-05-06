# frozen_string_literal: true

require "ivar"

# Base class for all food items
class Food
  include Ivar::Checked

  # Declare common properties with positional initialization and defaults
  ivar :@name, init: :positional, value: "Unknown Food"
  ivar :@calories, init: :positional, value: 0
  ivar :@vegetarian, init: :positional, value: false
  ivar :@vegan, init: :positional, value: false

  # Declare extra_info
  ivar :@extra_info

  def initialize(extra_info = nil)
    # The declared variables are already initialized from positional arguments or defaults
    @extra_info = extra_info
  end

  def to_s
    result = "#{@name} (#{@calories} calories)"
    result += ", vegetarian" if @vegetarian
    result += ", vegan" if @vegan
    result += ", #{@extra_info}" if @extra_info
    result
  end
end

# Sandwich class that inherits from Food
class Sandwich < Food
  # Override name with a more specific default
  ivar :@name, value: "Sandwich"

  # Declare sandwich-specific properties
  ivar :@bread, init: :positional, value: "white"
  ivar :@fillings, init: :positional, value: []

  # Override vegetarian with a different default
  ivar :@vegetarian, value: true

  def initialize(condiments = [], *args)
    # Pass any remaining args to parent
    super(*args)

    # Initialize fillings if needed
    @fillings ||= []

    # Add condiments to fillings
    @fillings += condiments
  end

  def to_s
    result = super
    result += " on #{@bread} bread"
    result += " with #{@fillings.join(", ")}" unless @fillings.empty?
    result
  end
end

# VeganSandwich class that inherits from Sandwich
class VeganSandwich < Sandwich
  # Override defaults for vegan properties
  ivar :@name, value: "Vegan Sandwich"
  ivar :@vegan, value: true

  # Override bread default
  ivar :@bread, value: "whole grain"

  # Add vegan-specific properties
  ivar :@plant_protein, init: :positional, value: "tofu"

  def initialize(*args)
    super

    # Initialize fillings if needed
    @fillings ||= []

    # Ensure no non-vegan fillings
    @fillings.reject! { |filling| non_vegan_fillings.include?(filling) }

    # Add plant protein if fillings are empty
    @fillings << @plant_protein if @fillings.empty?
  end

  def non_vegan_fillings
    ["cheese", "mayo", "ham", "turkey", "roast beef", "tuna"]
  end
end

# Create a basic food item with positional arguments
# (name, calories, vegetarian, vegan)
apple = Food.new("Apple", 95, true, true, "Fresh and crisp")
puts "Food: #{apple}"
# => "Food: Apple (95 calories), vegetarian, vegan, Fresh and crisp"

# Create a sandwich with positional arguments
# (bread, fillings, name, calories, vegetarian, vegan, extra_info)
# Note: condiments is a separate parameter not part of the ivar declarations
turkey_sandwich = Sandwich.new(
  ["mustard", "mayo"],  # condiments
  "wheat",              # bread
  ["turkey", "lettuce", "tomato"], # fillings
  "Turkey Sandwich",    # name
  450,                  # calories
  false,                # vegetarian
  false,                # vegan
  "Classic lunch option" # extra_info
)
puts "Sandwich: #{turkey_sandwich}"
# => "Sandwich: Turkey Sandwich (450 calories), Classic lunch option on wheat bread with turkey, lettuce, tomato, mustard, mayo"

# Create a vegan sandwich with positional arguments
# (plant_protein, bread, fillings, name, calories, vegetarian, vegan, extra_info)
vegan_sandwich = VeganSandwich.new(
  ["hummus", "mustard"], # condiments
  "tempeh",              # plant_protein
  "rye",                 # bread
  ["lettuce", "tomato", "avocado"], # fillings
  "Tempeh Sandwich",     # name
  350,                   # calories
  true,                  # vegetarian
  true,                  # vegan
  "High protein option"  # extra_info
)
puts "Vegan Sandwich: #{vegan_sandwich}"
# => "Vegan Sandwich: Tempeh Sandwich (350 calories), vegetarian, vegan, High protein option on rye bread with lettuce, tomato, avocado, hummus, mustard"

# Create items with default values
default_food = Food.new
default_sandwich = Sandwich.new
default_vegan = VeganSandwich.new

puts "\nDefaults:"
puts "Default Food: #{default_food}"
# => "Default Food: Unknown Food (0 calories)"
puts "Default Sandwich: #{default_sandwich}"
# => "Default Sandwich: Sandwich (0 calories), vegetarian on white bread"
puts "Default Vegan Sandwich: #{default_vegan}"
# => "Default Vegan Sandwich: Vegan Sandwich (0 calories), vegetarian, vegan on whole grain bread with tofu"
