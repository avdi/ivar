# frozen_string_literal: true

require "ivar"

class SandwichWithAccessors
  include Ivar::Checked

  # Declare instance variables with accessors
  ivar :@bread, :@cheese, accessor: true, value: "default"
  
  # Declare condiments with a reader
  ivar :@condiments, reader: true, value: ["mayo", "mustard"]
  
  # Declare pickles with a writer
  ivar :@pickles, writer: true, value: true
  
  # Declare a variable without any accessors
  ivar :@side

  def initialize(options = {})
    # Override defaults if options provided
    @bread = options[:bread] if options[:bread]
    @cheese = options[:cheese] if options[:cheese]
    
    # Add extra condiments if provided
    @condiments += options[:extra_condiments] if options[:extra_condiments]
    
    # Set pickles based on options
    @pickles = options[:pickles] if options.key?(:pickles)
    
    # Set side if provided
    @side = options[:side] if options[:side]
  end
  
  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if defined?(@side) && @side
    result
  end
  
  # Custom reader for side since we didn't create an accessor
  def side
    @side
  end
  
  # Custom method to toggle pickles
  def toggle_pickles
    @pickles = !@pickles
  end
end

# Create a sandwich with default values
sandwich = SandwichWithAccessors.new
puts "Default sandwich: #{sandwich}"
puts "Bread: #{sandwich.bread}"
puts "Cheese: #{sandwich.cheese}"
puts "Condiments: #{sandwich.condiments.join(", ")}"
puts "Side: #{sandwich.side.inspect}"

# Modify the sandwich using accessors
sandwich.bread = "rye"
sandwich.cheese = "swiss"
sandwich.pickles = false
puts "\nModified sandwich: #{sandwich}"

# Create a sandwich with custom options
custom = SandwichWithAccessors.new(
  bread: "sourdough",
  cheese: "provolone",
  extra_condiments: ["pesto"],
  pickles: false,
  side: "chips"
)
puts "\nCustom sandwich: #{custom}"

# Toggle pickles and show the result
custom.toggle_pickles
puts "After toggling pickles: #{custom}"
