# frozen_string_literal: true

require "ivar"

# Base class for all food items
class Food
  include Ivar::Checked

  # Declare common properties with keyword initialization and defaults
  ivar :@name, init: :kwarg, value: "Unknown Food"
  ivar :@calories, init: :kwarg, value: 0
  ivar :@vegetarian, init: :kwarg, value: false
  ivar :@vegan, init: :kwarg, value: false

  # Declare extra_info
  ivar :@extra_info

  def initialize(extra_info: nil)
    # The declared variables are already initialized from keyword arguments or defaults
    @extra_info = :extra_info
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
  ivar :@bread, init: :kwarg, value: "white"
  ivar :@fillings, init: :kwarg, value: []

  # Override vegetarian with a different default
  ivar :@vegetarian, value: true

  def initialize(condiments: [], **kwargs)
    # Pass any remaining kwargs to parent
    super(**kwargs)

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
  ivar :@plant_protein, init: :kwarg, value: "tofu"

  def initialize(**kwargs)
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

  def to_s
    result = super
    result += " (#{@plant_protein} based)" if @fillings.include?(@plant_protein)
    result
  end
end

# Create a basic food item with defaults
puts "Basic food with defaults:"
food = Food.new
puts food
# => "Unknown Food (0 calories)"

# Create a food item with custom properties
puts "\nCustom food:"
custom_food = Food.new(name: "Apple", calories: 95, vegetarian: true, vegan: true)
puts custom_food
# => "Apple (95 calories), vegetarian, vegan"

# Create a sandwich with defaults
puts "\nDefault sandwich:"
sandwich = Sandwich.new
puts sandwich
# => "Sandwich (0 calories), vegetarian on white bread"

# Create a sandwich with custom properties
puts "\nCustom sandwich:"
custom_sandwich = Sandwich.new(
  name: "Club Sandwich",
  calories: 450,
  bread: "sourdough",
  fillings: ["turkey", "bacon", "lettuce", "tomato"],
  condiments: ["mayo", "mustard"],
  extra_info: "triple-decker"
)
puts custom_sandwich
# => "Club Sandwich (450 calories), vegetarian on sourdough bread with turkey, bacon, lettuce, tomato, mayo, mustard, triple-decker"

# Create a vegan sandwich with defaults
puts "\nDefault vegan sandwich:"
vegan_sandwich = VeganSandwich.new
puts vegan_sandwich
# => "Vegan Sandwich (0 calories), vegetarian, vegan on whole grain bread with tofu (tofu based)"

# Create a vegan sandwich with custom properties
puts "\nCustom vegan sandwich:"
custom_vegan = VeganSandwich.new(
  name: "Mediterranean Vegan",
  calories: 380,
  bread: "pita",
  fillings: ["hummus", "falafel", "lettuce", "tomato", "cucumber"],
  plant_protein: "chickpeas",
  extra_info: "with tahini sauce"
)
puts custom_vegan
# => "Mediterranean Vegan (380 calories), vegetarian, vegan on pita bread with hummus, falafel, lettuce, tomato, cucumber, with tahini sauce"

# Try to create a vegan sandwich with non-vegan fillings
puts "\nVegan sandwich with non-vegan fillings (will be removed):"
non_vegan_fillings = VeganSandwich.new(
  fillings: ["cheese", "ham", "lettuce", "tomato"],
  plant_protein: "seitan"
)
puts non_vegan_fillings
# => "Vegan Sandwich (0 calories), vegetarian, vegan on whole grain bread with lettuce, tomato, seitan (seitan based)"
