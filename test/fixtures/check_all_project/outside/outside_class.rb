# frozen_string_literal: true

# This class is defined outside the project
class OutsideClass
  def initialize
    @name = "outside"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end
