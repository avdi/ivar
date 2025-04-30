# frozen_string_literal: true

# This class is intentionally split between two files
class SplitClass
  def initialize
    @part1_var1 = "value1"
    @part1_var2 = "value2"
  end

  def part1_method
    "Using #{@part1_var1} and #{@part1_var2}"
  end
end
