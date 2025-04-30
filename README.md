# Ivar

Ruby instance variables are so convenient - you don't even need to declare them! But... they are also dangerous, because a mispelled variable name results in `nil` instead of an error.

Why not have the best of both worlds? Ivar lets you use plain-old instance variables, and automatically checks for typos.

Ivar waits until an instance is created to do the checking, then uses Prism to look for variables that don't match what was set in initialization. So it's a little bit dynamic, a little bit static. It doesn't encumber your instance variable reads and writes with any extra checking. And with the `:warn_once` policy, it won't overwhelm you with output.


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

Too many warnings? Try this:

```ruby
# sandwich_once.rb
require "ivar"

class Sandwich
  include Ivar::Checked
  ivar_check_policy :warn_once

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
$ ruby sandwich_once.rb -w
sandwich_once.rb:15: warning: unknown instance variable @chese. Did you mean: @cheese?
```

Setting `ivar_check_policy :warn_once` makes `check_ivars` use the `warn_once` policy, which means it will emit warnings only for the first instance of each class.

### Pre-declaring Instance Variables

Normally we "declare" variables by setting them in `initialize`. But if you don't have any reason to set them in the initializer, you can still declare them so they won't be flagged.

```ruby
# sandwich_with_ivar_macro.rb
require "ivar"

class SandwichWithIvarMacro
  include Ivar::Checked

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

Note: this WILL set the variable to `nil` before `initialize` runs, so if you have code that depends on `defined?(@var)` it may break. If folks want it we might look into non-setting predeclaration.

### Setting ivars from initializer keyword arguments

While we're messing around with ivars, let's fix Ruby's oldest missing convenience feature:

```ruby
# sandwich_with_kwarg.rb
require "ivar"

class SandwichWithKwarg
  include Ivar::Checked

  ivar kwarg: [:@bread, :@cheese, :@condiments, :@pickles, :@side]

  def to_s
    result = "A #{@bread} sandwich with #{@cheese}"
    result += " and #{@condiments.join(", ")}" unless @condiments.empty?
    result += " with pickles" if @pickles
    result += " and a side of #{@side}" if @side
    result
  end
end

# Create a sandwich with keyword arguments
sandwich = SandwichWithKwarg.new(
  bread: "wheat",
  cheese: "muenster",
  condiments: ["mayo", "mustard"],
  side: "chips"
)

puts sandwich.to_s  # Outputs: A wheat sandwich with muenster and mayo, mustard and a side of chips
```

Ta-da, no more tedious setting of instance variables from arguments of the same name.

TODO: Find a positional args version of this that makes sense.

### Inheritance

This stuff works with inheritance:

```ruby
class BaseSandwich
  include Ivar::Checked

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

## Checking Policies

Ivar supports different policies for handling unknown instance variables. You can specify a policy at the global level, class level, or per-check level.

### Available Policies

- `:warn` - Emit warnings for all unknown instance variables (default)
- `:warn_once` - Emit warnings only once per class
- `:raise` - Raise an exception for unknown instance variables
- `:log` - Log unknown instance variables to a logger

### Setting a Global Policy

```ruby
# Set the global policy to raise exceptions
Ivar.check_policy = :raise

class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    check_ivars
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will raise an exception
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Setting a Class-Level Policy

```ruby
class Sandwich
  include Ivar::Validation
  extend Ivar::CheckPolicy

  # Set the class-level policy to log
  ivar_check_policy :log, logger: Logger.new($stderr)

  def initialize
    @bread = "wheat"
    check_ivars
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will log a warning
  end
end

Sandwich.new  # Logs: W, [2023-06-01T12:34:56.789123 #12345] WARN -- : test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Setting a Per-Check Policy

```ruby
class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    # Use the raise policy for this check
    check_ivars(policy: :raise)
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Using the Checked Module with Policies

The `Checked` module sets a default policy:

- `Checked` sets the policy to `:warn`

You can override the default policy:

```ruby
class Sandwich
  include Ivar::Checked

  # Override the default policy
  ivar_check_policy :raise

  def initialize
    @bread = "wheat"
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will raise an exception
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

# Acknowledgements

Thank you to Joel Drapper, for inspiring me with [the strict_ivars gem](https://github.com/joeldrapper/strict_ivars).



# TODO

- Pre-declare "ghost" variables without setting them
- Add a module for dynamic checking of instance_variable_get/set