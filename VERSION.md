# Versioning and Release Process

This project follows [Semantic Versioning](https://semver.org/) (SemVer).

## Version Numbers

Version numbers are in the format `MAJOR.MINOR.PATCH`:

- **MAJOR**: Incremented for incompatible API changes
- **MINOR**: Incremented for new functionality in a backward-compatible manner
- **PATCH**: Incremented for backward-compatible bug fixes

## Release Process

To release a new version:

1. Make sure all changes are documented in the `CHANGELOG.md` file under the "Unreleased" section
2. Run the release script with the appropriate version bump type:
   ```
   script/release [major|minor|patch]
   ```
3. The script will:
   - Run tests and linter to ensure everything is working
   - Update the version number in `lib/ivar/version.rb`
   - Update the `CHANGELOG.md` file with the new version and date
   - Commit these changes
   - Create a git tag for the new version
4. Push the changes and tag to GitHub:
   ```
   git push origin main && git push origin v{version}
   ```
5. The GitHub Actions workflow will automatically:
   - Build the gem
   - Run tests
   - Publish the gem to RubyGems.org

## Setting Up RubyGems API Key

To allow GitHub Actions to publish to RubyGems.org, you need to add your RubyGems API key as a secret:

1. Get your API key from RubyGems.org (account settings)
2. Go to your GitHub repository settings
3. Navigate to "Secrets and variables" → "Actions"
4. Add a new repository secret named `RUBYGEMS_API_KEY` with your RubyGems API key as the value
