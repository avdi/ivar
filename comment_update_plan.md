# Comment Update Plan for Ivar Project

## Project Guidelines for Comments

Based on the workspace rules and codebase analysis, the following guidelines should be followed:

1. **Avoid inline comments** - Prefer using:
   - Explaining variables
   - Intention-revealing method names
   - The "composed method" pattern where appropriate

2. **Acceptable comments**:
   - Class-level documentation comments
   - Module-level documentation comments
   - Method-level documentation comments

3. **Code Style**:
   - Use modern Ruby 3.4 style and features
   - Follow Standard Ruby linting rules
   - Prefer basic Ruby data types to building new abstractions

## Files to Review and Update

### Core Library Files

- [x] lib/ivar.rb
- [x] lib/ivar/auto_check.rb
- [x] lib/ivar/check_all.rb
- [x] lib/ivar/check_all_manager.rb
- [x] lib/ivar/checked.rb
- [x] lib/ivar/macros.rb
- [x] lib/ivar/policies.rb
- [x] lib/ivar/prism_analysis.rb
- [x] lib/ivar/project_root.rb
- [x] lib/ivar/validation.rb
- [x] lib/ivar/version.rb

### Test Files

- [x] test/test_check_all.rb
- [x] test/test_checked_once_integration.rb
- [x] test/test_ivar.rb
- [x] test/test_helper.rb

### Example Files

- [x] examples/check_all_block_example.rb
- [x] examples/check_all_example.rb
- [x] examples/require_check_all_example.rb
- [x] examples/sandwich_inheritance.rb
- [x] examples/sandwich_with_accessors.rb
- [x] examples/sandwich_with_checked.rb
- [x] examples/sandwich_with_checked_once.rb
- [x] examples/sandwich_with_ivar_block.rb
- [x] examples/sandwich_with_ivar_macro.rb

## Comment Update Strategy

For each file:

1. **Identify inline comments** that explain "how" code works rather than "why"
2. **Evaluate if the comment can be replaced** by:
   - Renaming variables to be more descriptive
   - Extracting code to well-named methods
   - Using Ruby's expressive syntax to make the code self-documenting
3. **Keep documentation comments** for classes, modules, and methods
4. **Update remaining comments** to be more concise and focused on "why" not "how"
5. **Run standardrb** to ensure code follows style guidelines

## Progress Tracking

As files are updated, they will be checked off in this list.
