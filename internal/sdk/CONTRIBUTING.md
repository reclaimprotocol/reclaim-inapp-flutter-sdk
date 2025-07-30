# Contributing to Reclaim In-App SDK

Welcome to the Reclaim In-App SDK project! This is a Flutter package that provides an in-app SDK for integrating Reclaim Protocol functionality into Flutter applications.

## Project Structure

The project follows a standard Flutter package structure:
- `lib/` - Contains the main package code
  - `src/` - Contains the implementation details
  - `reclaim_inapp_sdk.dart` - The main barrel file that exports public APIs

## Barrel Exports

When contributing to this project, please follow these guidelines regarding barrel exports:

1. Only export files and APIs that are intended to be public and consumed by package users
2. Keep implementation details in the `src/` directory
3. Use the main barrel file (`reclaim_inapp_sdk.dart`) to expose public APIs
4. Do not export internal implementation details or utilities

## Getting Started

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Make your changes
4. Run tests and ensure they pass
5. Submit a pull request

## Code Style

- Please follow the Dart style guide and ensure your code passes the analysis checks. The project includes an `analysis_options.yaml` file that defines the linting rules.
- Run `dart format .` before commiting to ensure consistent source code formatting.
- Review code architecture document at [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- These are two good guides for code stytle and naming schemes:
  - https://dart.dev/effective-dart/style 
  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/Articles/NamingIvarsAndTypes.html

## Testing

All new features should include appropriate tests. Run the test suite before submitting your pull request:

```bash
flutter test
```

## Pull Request Process

1. Update the CHANGELOG.md with details of your changes
2. Ensure your code follows the project's style guidelines
3. Include tests for new functionality
4. Update documentation if necessary
5. Submit your pull request with a clear description of the changes

Thank you for contributing to the Reclaim In-App SDK!
