# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
