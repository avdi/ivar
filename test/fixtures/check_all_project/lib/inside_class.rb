# frozen_string_literal: true

# This class is defined inside the project
class InsideClass
  def initialize
    @name = "inside"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end
