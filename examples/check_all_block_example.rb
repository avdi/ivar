# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ivar"

# Define a class before enabling check_all
class BeforeClass
  def initialize
    @name = "before"
  end

  def to_s
    "Name: #{@naem}"  # Intentional typo to demonstrate lack of checking
  end
end

# Define classes that will be used within the block
class WithinBlockClass
  def initialize
    @name = "within block"
  end

  def to_s
    "Name: #{@naem}"  # Intentional typo to demonstrate lack of checking yet
  end
end

module WithinBlockModule
  class NestedClass
    def initialize
      @name = "nested"
    end

    def to_s
      "Name: #{@naem}"  # Intentional typo to demonstrate lack of checking yet
    end
  end
end

# Only classes loaded within this block will have Ivar::Checked included
Ivar.check_all do
  # Load the classes by referencing them
  puts "Loading WithinBlockClass: #{WithinBlockClass}"
  puts "Loading WithinBlockModule::NestedClass: #{WithinBlockModule::NestedClass}"

  # We could also define anonymous classes here
  @anonymous_class = Class.new do
    def initialize
      @name = "anonymous"
    end

    def to_s
      "Name: #{@naem}"  # Intentional typo to demonstrate checking
    end
  end
end

# Define a class after the check_all block
class AfterClass
  def initialize
    @name = "after"
  end

  def to_s
    "Name: #{@naem}"  # Intentional typo to demonstrate lack of checking
  end
end

# Create instances of each class
puts "Creating BeforeClass instance:"
before = BeforeClass.new
puts before

puts "\nCreating WithinBlockClass instance:"
within = WithinBlockClass.new
puts within

puts "\nCreating WithinBlockModule::NestedClass instance:"
nested = WithinBlockModule::NestedClass.new
puts nested

puts "\nCreating AfterClass instance:"
after = AfterClass.new
puts after
