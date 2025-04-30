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

### Inheritance

Both modules also work with inheritance:

```ruby
class BaseSandwich
  include Ivar::Checked # or Ivar::CheckedOnce

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
  end
end

class SpecialtySandwich < BaseSandwich
  def initialize
    super
    @condiments = ["mayo", "mustard"]
  end

  def to_s
    "A #{@bread} sandwich with #{@cheese} and #{@condimants.join(", ")}"
  end
end

SpecialtySandwich.new
```

```shell
$ ruby inheritance_example.rb -w
inheritance_example.rb:17: warning: unknown instance variable @condimants. Did you mean: @condiments?
```
