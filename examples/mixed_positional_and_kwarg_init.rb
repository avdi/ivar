# frozen_string_literal: true

require "ivar"

class Recipe
  include Ivar::Checked

  # Declare instance variables with positional initialization
  ivar :@name, init: :positional, value: "Unnamed Recipe"
  ivar :@servings, init: :positional, value: 4

  # Declare instance variables with keyword initialization
  ivar :@prep_time, init: :kwarg, value: 15
  ivar :@cook_time, init: :kwarg, value: 30
  ivar :@difficulty, init: :kwarg, value: "medium"

  # Regular instance variables
  ivar :@ingredients, value: []
  ivar :@instructions, value: []

  def initialize(ingredients = [], instructions = [])
    # At this point, @name and @servings are set from positional args
    # @prep_time, @cook_time, and @difficulty are set from keyword args
    @ingredients = ingredients unless ingredients.empty?
    @instructions = instructions unless instructions.empty?
  end

  def total_time
    @prep_time + @cook_time
  end

  def to_s
    result = "#{@name} (Serves: #{@servings})\n"
    result += "Prep: #{@prep_time} min, Cook: #{@cook_time} min, Difficulty: #{@difficulty}\n"
    result += "\nIngredients:\n"
    @ingredients.each { |ingredient| result += "- #{ingredient}\n" }
    result += "\nInstructions:\n"
    @instructions.each_with_index { |instruction, i| result += "#{i + 1}. #{instruction}\n" }
    result
  end
end

class DessertRecipe < Recipe
  # Additional positional parameters
  ivar :@dessert_type, init: :positional, value: "cake"
  # Additional keyword parameters
  ivar :@sweetness, init: :kwarg, value: "medium"
  ivar :@calories_per_serving, init: :kwarg, value: 300

  def initialize(special_equipment = [], *args, **kwargs)
    @special_equipment = special_equipment
    super(*args, **kwargs)
  end

  def to_s
    result = super
    result += "\nDessert Type: #{@dessert_type}\n"
    result += "Sweetness: #{@sweetness}, Calories: #{@calories_per_serving} per serving\n"
    result += "\nSpecial Equipment:\n"
    @special_equipment.each { |equipment| result += "- #{equipment}\n" } unless @special_equipment.empty?
    result
  end
end

# Create a basic recipe with positional and keyword arguments
pasta_recipe = Recipe.new(
  "Spaghetti Carbonara",  # name (positional)
  2,                      # servings (positional)
  [                       # ingredients (regular parameter)
    "200g spaghetti",
    "100g pancetta",
    "2 large eggs",
    "50g pecorino cheese",
    "50g parmesan",
    "Freshly ground black pepper"
  ],
  [                       # instructions (regular parameter)
    "Cook the spaghetti in salted water.",
    "Fry the pancetta until crispy.",
    "Whisk the eggs and cheese together.",
    "Drain pasta, mix with pancetta, then quickly mix in egg mixture.",
    "Season with black pepper and serve immediately."
  ],
  prep_time: 10,          # prep_time (keyword)
  cook_time: 15,          # cook_time (keyword)
  difficulty: "easy"      # difficulty (keyword)
)

puts "Basic Recipe:\n#{pasta_recipe}\n\n"

# Create a dessert recipe with positional and keyword arguments
chocolate_cake = DessertRecipe.new(
  ["Stand mixer", "9-inch cake pans", "Cooling rack"],  # special_equipment (regular parameter)
  "chocolate",                                          # dessert_type (positional)
  "Chocolate Layer Cake",                               # name (positional)
  12,                                                   # servings (positional)
  [                                                     # ingredients (regular parameter)
    "2 cups all-purpose flour",
    "2 cups sugar",
    "3/4 cup unsweetened cocoa powder",
    "2 tsp baking soda",
    "1 tsp salt",
    "2 large eggs",
    "1 cup buttermilk",
    "1/2 cup vegetable oil",
    "2 tsp vanilla extract",
    "1 cup hot coffee"
  ],
  [                                                     # instructions (regular parameter)
    "Preheat oven to 350°F (175°C).",
    "Mix dry ingredients in a large bowl.",
    "Add eggs, buttermilk, oil, and vanilla; beat for 2 minutes.",
    "Stir in hot coffee (batter will be thin).",
    "Pour into greased and floured cake pans.",
    "Bake for 30-35 minutes.",
    "Cool completely before frosting."
  ],
  prep_time: 25,                                        # prep_time (keyword)
  cook_time: 35,                                        # cook_time (keyword)
  difficulty: "medium",                                 # difficulty (keyword)
  sweetness: "high",                                    # sweetness (keyword)
  calories_per_serving: 450                             # calories_per_serving (keyword)
)

puts "Dessert Recipe:\n#{chocolate_cake}"
