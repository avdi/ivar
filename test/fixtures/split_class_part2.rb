# frozen_string_literal: true

# This file adds more methods to the SplitClass
class SplitClass
  def part2_method
    @part2_var1 = "another value"
    @part2_var2 = "yet another value"
    "Using #{@part2_var1} and #{@part2_var2} and #{@part2_var3}"
  end
end
