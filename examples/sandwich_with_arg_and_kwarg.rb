# frozen_string_literal: true

require "ivar"

class SandwichWithArgAndKwarg
  include Ivar::Checked

  # Pre-declare instance variables to be initialized from both positional and keyword arguments
  ivar :@pickles, :@side, arg: %i[@bread @cheese], kwarg: [:@condiments]

  def initialize(*args, **_kwargs)
    # NOTE: @bread and @cheese are already set from positional arguments
    # Note: @condiments and @pickles are already set from keyword arguments
    # We only need to handle the remaining arguments
    @side = args[0] if args.length > 0
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" if @condiments && !@condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if @side
    result
  end
end

# Create a sandwich with both positional and keyword arguments
sandwich = SandwichWithArgAndKwarg.new(
  "wheat",
  "muenster",
  "chips",
  condiments: %w[mayo mustard],
  pickles: true
)

puts sandwich # Outputs: A wheat sandwich with muenster and mayo, mustard with pickles and a side of chips

# Create another sandwich with different arguments
sandwich2 = SandwichWithArgAndKwarg.new(
  "rye",
  "swiss",
  condiments: ["mustard"]
)

puts sandwich2 # Outputs: A rye sandwich with swiss and mustard
