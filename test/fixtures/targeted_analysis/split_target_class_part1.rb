# frozen_string_literal: true

# This class is intentionally split between two files
class SplitTargetClass
  def initialize
    @part1_var1 = "value1"
    @part1_var2 = "value2"
  end

  def part1_method
    @part1_var1 = "modified"
    @part1_var2 = "also modified"
    "Using #{@part1_var1} and #{@part1_var2}"
  end
end
