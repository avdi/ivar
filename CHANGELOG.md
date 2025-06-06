# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Updated policies to use Ruby's built-in `warn` method instead of `$stderr.write`
- Reduced duplication in policy classes by moving common warning logic to the base class

## [0.4.7] - 2025-05-07

## [0.4.6] - 2025-05-07

## [0.4.5] - 2025-05-07

## [0.4.4] - 2025-05-07

### Changed
- Enhanced release script to detect and handle uncommitted changes after the release process
- Improved release script to update Gemfile.lock before committing version changes

## [0.4.2] - 2025-05-07

### Added
- Enhanced release script to automatically push changes and tags to the remote repository

### Fixed
- Fixed release script to include Gemfile.lock changes in version bump commit
- Fixed GitHub Actions workflow to prevent "frozen Gemfile.lock" errors during gem publishing

## [0.4.0] - 2025-05-07

### Added
- Support for initializing instance variables from keyword arguments using `ivar :@foo, init: :kwarg` or `ivar :@foo, init: :keyword`
- Proper inheritance handling for keyword argument initialization, with child class declarations taking precedence over parent class declarations
- Added Ivar::Manifest class to formalize tracking of instance variables
- Added ExplicitDeclaration and ImplicitDeclaration classes to represent different types of variable declarations
- Added callbacks for declarations: on_declare and before_init
- Added CheckPolicy module to handle class-level check policy configuration
- Added support for policy inheritance in subclasses
- Added method stash abstraction with `stash_method`, `get_method_stash`, and `get_stashed_method` on the Ivar module
- Added `get_or_create_manifest` method to make it clearer when a manifest may be created

### Changed
- Split declaration classes into separate files for better organization:
  - `Declaration` → `lib/ivar/declaration.rb`
  - `ExplicitDeclaration` → `lib/ivar/explicit_declaration.rb`
  - `ExplicitKeywordDeclaration` → `lib/ivar/explicit_keyword_declaration.rb`
  - `ExplicitPositionalDeclaration` → `lib/ivar/explicit_positional_declaration.rb`
- Centralized handling of internal variables (those starting with `@__ivar_`) to avoid explicit declarations
- Improved filtering of internal variables during analysis phase rather than validation phase
- Refactored internal variable tracking to use the Manifest system
- Removed backwards compatibility variables (@__ivar_declared_ivars, @__ivar_initial_values, @__ivar_init_methods)
- Improved manifest ancestry handling to walk the entire ancestor chain instead of just the direct parent
- Enhanced declaration inheritance to properly handle overrides from modules and included mixins
- Optimized manifest ancestry to avoid creating unnecessary manifests for classes/modules that don't declare anything
- Simplified Manifest class to use a single declarations hash instead of separate explicit and implicit declarations
- Improved Manifest API with clearer separation between declarations (array of values) and declarations_by_name (hash)
- Simplified initialization process by combining keyword argument handling into the before_init callback
- Refactored Checked module to use the CheckPolicy module for policy configuration
- Changed default policy for Checked module from :warn_once to :warn
- Enhanced initialization process in Checked module to properly handle manifest processing
- Simplified external-process tests to directly check for warnings in stderr instead of using custom capture logic
- Updated TargetedPrismAnalysis and Checked::InstanceMethods to use the new method stash abstraction
- Extracted modules from auto_check.rb into their own files and removed auto_check.rb
- Removed PrismAnalysis class as it has been superseded by TargetedPrismAnalysis

### Documentation
- Improved documentation for the CheckPolicy module explaining its purpose and inheritance behavior
- Enhanced documentation for the Checked module detailing its functionality and initialization process
- Added comprehensive documentation for the Manifest#add_implicits method explaining its role in tracking instance variables
- Added documentation for the new method stash abstraction methods

## [0.3.2] - 2025-05-05

## [0.3.1] - 2025-05-05

## [0.3.0] - 2025-05-05

### Added
- Support for initializing multiple instance variables to the same value using `ivar :@foo, :@bar, value: 123`
- Support for ivar declarations with a block that generates default values based on the variable name
- Support for reader, writer, and accessor keyword arguments to automatically generate attr methods

### Changed
- Extracted check_all functionality to its own class (CheckAllManager) for better organization
- Converted module instance variables to constants where appropriate
- Moved scripts from bin/ to script/ directory for better organization
- Improved development environment with consistent line endings and editor configuration

### Fixed
- Fixed missing trailing newlines in files
- Fixed Gemfile.lock version synchronization
- Fixed release script to use $stdin.gets instead of gets

## [0.2.1] - 2025-05-05

### Added
- Release automation via GitHub Actions

## [0.2.0] - 2025-05-01

### Added
- CheckDynamic module that overrides instance_variable_get/set to check against a list of allowed variables saved at the end of initialization

## [0.1.0] - 2025-04-29

### Added
- Initial release
