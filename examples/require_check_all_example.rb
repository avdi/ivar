# frozen_string_literal: true

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# This automatically enables Ivar.check_all
require "ivar/check_all"

# Now all classes and modules defined in the project will have Ivar::Checked included
class Sandwich
  def initialize
    @bread = "wheat"
    @cheese = "muenster"
  end

  def to_s
    # Intentional typo in @cheese
    "A #{@bread} sandwich with #{@chese}"
  end
end

# Create a sandwich - this will automatically check instance variables
sandwich = Sandwich.new
puts sandwich
