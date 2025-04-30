# Ivar

A Ruby gem for detecting typos in instance variable names.

## Usage

### Manual Validation

```ruby
# sandwich.rb
require "ivar"

class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
    check_ivars(add: [:@side])
  end

  def to_s
    "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}" \
    (@side ? "and a side of #{@side}" : "")
  end
end

Sandwich.new
```

```shell
$ ruby sandwich.rb -w
sandwich.rb:22: warning: unknown instance variable @chese. Did you mean: @cheese?
```

### Automatic Validation (Every Instance)

```ruby
# sandwich_automatic.rb
require "ivar"

class Sandwich
  include Ivar::Checked

  def initialize
    @bread = "white"
    @cheese = "havarti"
    @condiments = ["mayo", "mustard"]
    # no need for explicit check_ivars call
  end

  def to_s
    "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
  end
end

Sandwich.new
```

```shell
$ ruby sandwich_automatic.rb -w
sandwich_automatic.rb:15: warning: unknown instance variable @chese. Did you mean: @cheese?
```

The `Checked` module automatically calls `check_ivars` after initialization, which means it will emit warnings for every instance of the class.

### Automatic Validation (Once Per Class)

```ruby
# sandwich_once.rb
require "ivar"

class Sandwich
  include Ivar::CheckedOnce

  def initialize
    @bread = "white"
    @cheese = "havarti"
    @condiments = ["mayo", "mustard"]
    # no need for explicit check_ivars_once call
  end

  def to_s
    "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}"
  end
end

Sandwich.new
```

```shell
$ ruby sandwich_once.rb -w
sandwich_once.rb:15: warning: unknown instance variable @chese. Did you mean: @cheese?
```

The `CheckedOnce` module automatically calls `check_ivars_once` after initialization, which means it will emit warnings only for the first instance of each class.

### Pre-declaring Instance Variables

You can pre-declare instance variables that should be initialized to `nil` before the initializer is called. This is useful for variables that might be referenced before they are explicitly set:

```ruby
# sandwich_with_ivar_macro.rb
require "ivar"

class SandwichWithIvarMacro
  include Ivar::Checked # or Ivar::CheckedOnce

  # Pre-declare only instance variables that might be referenced before being set
  # You don't need to include variables that are always set in initialize
  ivar :@side

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
    # Note: @side is not set here, but it's pre-initialized to nil
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}"
    # This won't trigger a warning because @side is pre-initialized
    result += " and a side of #{@side}" if @side
    result
  end

  def add_side(side)
    @side = side
  end
end

sandwich = SandwichWithIvarMacro.new
puts sandwich.to_s  # No warning about @side

sandwich.add_side("chips")
puts sandwich.to_s
```

The `ivar` macro pre-initializes the specified instance variables to `nil` before the initializer is called, which prevents warnings about unknown instance variables. You only need to pre-declare variables that might be referenced before they are explicitly set - variables that are always set in the initializer don't need to be pre-declared.

### Using a Block with the `ivar` Macro

You can also provide a block to the `ivar` macro that will be executed in the context of the instance before initialization. This allows you to set up instance variables with specific values before the initializer is called:

```ruby
# sandwich_with_ivar_block.rb
require "ivar"

class SandwichWithIvarBlock
  include Ivar::Checked # or Ivar::CheckedOnce

  # Pre-declare instance variables with a block that runs before initialization
  ivar :@side do
    @pickles = true
    @condiments = []
  end

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    # Note: @pickles is already set to true by the ivar block
    # Note: @condiments is already initialized to an empty array by the ivar block
    @condiments << "mayo" if !@pickles
    @condiments << "mustard"
    # Note: @side is not set here, but it's pre-initialized to nil
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if @side
    result
  end

  def add_side(side)
    @side = side
  end
end

sandwich = SandwichWithIvarBlock.new
puts sandwich.to_s  # Outputs: A wheat sandwich with muenster and mustard with pickles

sandwich.add_side("chips")
puts sandwich.to_s  # Outputs: A wheat sandwich with muenster and mustard with pickles and a side of chips
```

The block is executed after pre-initializing any explicitly declared instance variables to `nil`, but before the class's `initialize` method is called. This allows you to set up default values or perform other initialization tasks that should happen before the main initialization logic.

### Inheritance

Both modules also work with inheritance:

```ruby
class BaseSandwich
  include Ivar::Checked # or Ivar::CheckedOnce

  # Pre-declare only variables that might be referenced before being set
  # Variables set in initialize (@bread, @cheese) don't need to be pre-declared
  ivar :@optional_topping

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
  end
end

class SpecialtySandwich < BaseSandwich
  # Add more pre-declared instance variables as needed
  # @condiments is set in initialize, so it doesn't need to be pre-declared
  ivar :@special_sauce

  def initialize
    super
    @condiments = ["mayo", "mustard"]
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese} and #{@condimants.join(", ")}"
    # @special_sauce is pre-declared, so this won't trigger a warning
    result += " with #{@special_sauce}" if @special_sauce
    # @optional_topping is inherited from the parent class
    result += " and #{@optional_topping}" if @optional_topping
    result
  end
end

SpecialtySandwich.new
```

```shell
$ ruby inheritance_example.rb -w
inheritance_example.rb:17: warning: unknown instance variable @condimants. Did you mean: @condiments?
```
