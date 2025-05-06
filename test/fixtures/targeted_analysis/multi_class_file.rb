# frozen_string_literal: true

# This file contains multiple class definitions

class FirstClass
  def initialize
    @first_var1 = "first class var1"
    @first_var2 = "first class var2"
  end

  def first_method
    @first_var1 = "modified"
    "Using #{@first_var1} and #{@first_var2}"
  end
end

class SecondClass
  def initialize
    @second_var1 = "second class var1"
    @second_var2 = "second class var2"
  end

  def second_method
    @second_var1 = "modified"
    "Using #{@second_var1} and #{@second_var2}"
  end
end
