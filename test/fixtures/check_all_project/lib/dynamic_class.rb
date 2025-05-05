# frozen_string_literal: true

# This file contains a function to dynamically create a class
def create_dynamic_class
  # Remove the class if it already exists
  Object.send(:remove_const, :DynamicClass) if defined?(DynamicClass)

  # Define a new class
  dynamic_class = Class.new do
    def initialize
      @name = "dynamic"
    end

    def to_s
      # Intentional typo in @name
      "Name: #{@naem}"
    end
  end

  # Assign the class to a constant
  Object.const_set(:DynamicClass, dynamic_class)

  # Return the class
  DynamicClass
end
