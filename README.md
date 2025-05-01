# Ivar

## Synopsis

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  def initialize(toppings)
    @toppings = toppings
  end

  def to_s
    "A pizza with #{@topings.join(", ")}"
  end
end

Pizza.new(["pepperoni", "mushrooms"])
```

```shell
$ ruby pizza.rb
pizza.rb:10: warning: unknown instance variable @topings. Did you mean: @toppings?
```

## Instroduction

Ruby instance variables are so convenient - you don't even need to declare them! But... they are also dangerous, because a mispelled variable name results in `nil` instead of an error.

For this reason it's often recommended to wrap every instance variable in getter and setter methods with `attr_accessor`. But this added ceremony is exactly what self-declaring instance variables are there to avoid.

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
require "ivar"

class Sandwich
  include Ivar::Checked

  def initialize
    @bread = "white"
    @cheese = "havarti"
    @condiments = ["mayo", "mustard"]
    # no need for explicit check_ivars call
  end
  # ...
end
```

The `Checked` module automatically calls `check_ivars` after initialization, which means it will emit warnings for every instance of the class.

### Automatic Validation (Once Per Class)

Too many warnings? Try this:

```ruby
require "ivar"

class Sandwich
  include Ivar::Checked
  ivar_check_policy :warn_once

  # ...
```

The `warn_once` policy means it will emit warnings only for the first instance of each class.

### Declare Instance Variables

Normally we "declare" variables by setting them in `initialize`. But if you don't have any reason to set them in the initializer, you can still declare them so they won't be flagged.

```ruby
require "ivar"

class SandwichWithIvarMacro
  include Ivar::Checked

  # Don't warn about @side even though it's not mentioned in initialize
  ivar :@side 

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
  end

  def add_side(side)
    @side = side
  end

  def to_s
    "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}" \
      " and a side of #{@side}" if @side
  end
end
```

Note: this WILL set the variable to `nil` before `initialize` runs, so if you have code that depends on `defined?(@var)` it may break. Lemme know if you want a non-setting form of predeclaration. Or just submit a PR.

### Setting ivars from initializer keyword arguments

While we're messing around with ivars, let's fix Ruby's oldest missing convenience feature:

```ruby
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

## Check Policies

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


And thanks to [Augment Code](https://www.augmentcode.com/), without which this gem wouldn't exist because I don't actually have time for pleasure projects anymore.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/avdi/ivar.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Releasing

This project uses a standardized release process:

1. Update the version number in `version.rb` according to [Semantic Versioning](https://semver.org/)
2. Update the CHANGELOG.md with your changes under the "Unreleased" section
3. Run the release script: `bin/release [major|minor|patch]`
4. Push the changes and tag: `git push origin main && git push origin v{version}`

For more details, see [VERSION.md](VERSION.md).

# TODO

- Pre-declare "ghost" variables without setting them
- Add a module for dynamic checking of instance_variable_get/set
- Audit and improve code the robot wrote
- Thread-safety