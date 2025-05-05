# frozen_string_literal: true

require "ivar"

class BaseSandwich
  include Ivar::Checked

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
  end

  def base_to_s
    "A #{@bread} sandwich with #{@cheese}"
  end
end

class SpecialtySandwich < BaseSandwich
  def initialize
    super
    @condiments = ["mayo", "mustard"]
    @special_sauce = "secret sauce"
  end

  def to_s
    result = "#{base_to_s} with #{@condiments.join(", ")}"
    result += " and #{@special_sause}"  # Intentional typo in @special_sauce
    result
  end
end

# Create a specialty sandwich - this will automatically check instance variables
SpecialtySandwich.new
