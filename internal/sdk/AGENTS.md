# Agent Guide for the Reclaim InApp SDK Repository

This document provides guidance for AI agents to effectively contribute to the Reclaim InApp SDK Flutter package.

## Guiding Principles for Contributions

- **Follow Dart Guidelines**: Strictly follow [Effective Dart](https://dart.dev/effective-dart) guidelines when writing Dart code
- **Format All Code**: Every code change must be formatted using `dart format`
- **Pass All Tests**: All changes must pass linting, analysis, and relevant tests
- **Follow Conventions**: Adhere to the repository's specific conventions and patterns
- **Document All Changes**: Public APIs must have dartdoc comments

## Project Overview

This is a Flutter SDK package that provides pre-built widgets to export user data with provable authenticity using HTTPS & Reclaim Protocol Zero-knowledge proof technology.

**IMPORTANT**: Review `docs/ARCHITECTURE.md` for detailed architecture guidelines and patterns before implementing features.

## Repository Structure

- `lib/src/` - Core implementation code
  - `data/` - Data models and serialization classes
  - `widgets/` - UI components
  - `utils/` - Utility functions
  - `overrides/` - Override system classes
- `example/` - Example application demonstrating SDK usage
- `assets/` - Icons and animations used by the SDK

## Effective Dart Guidelines

**IMPORTANT**: All code must strictly follow [Effective Dart](https://dart.dev/effective-dart) guidelines:

### Style
- DO name types using `UpperCamelCase`
- DO name libraries, packages, directories, and source files using `lowercase_with_underscores`
- DO name import prefixes using `lowercase_with_underscores`
- DO name other identifiers using `lowerCamelCase`
- PREFER using `lowerCamelCase` for constant names

### Documentation
- DO format comments like sentences
- DON'T use block comments for documentation
- DO use `///` doc comments to document members and types
- DO write doc comments for public APIs
- DO consider writing a library-level doc comment
- DO put doc comments before metadata annotations

### Usage
- DO use strings in `part of` directives
- DON'T import libraries that are inside the `src` directory of another package
- PREFER relative import paths
- DO use adjacent strings to concatenate string literals

### Design
- DO override `hashCode` if you override `==`
- DO make fields and top-level variables `final`
- AVOID public late final fields without initializers
- CONSIDER making your constructor `const` if the class supports it

## HTTP Client Usage

**IMPORTANT**: 
- **DO NOT use `dio`** - The dio package is being phased out
- **PREFER `ReclaimHttpClient`** - Use the custom HTTP client that handles caching, retries, and reliability features
- **Use `http` package** - For basic HTTP needs, use the standard `http` package
- **Migration**: When updating code, replace `dio` usage with `ReclaimHttpClient` or `http` package

Example of preferred HTTP usage:
```dart
// GOOD - Use ReclaimHttpClient
final response = await ReclaimHttpClient().get(url);

// GOOD - Use http package for simple cases
import 'package:http/http.dart' as http;
final response = await http.get(Uri.parse(url));

// BAD - Don't use dio
import 'package:dio/dio.dart'; // Avoid this
```

## Code Generation

### JSON Serialization
This project uses `json_annotation` and `json_serializable` (NOT freezed):

```dart
import 'package:json_annotation/json_annotation.dart';

part 'example.g.dart';

@JsonSerializable()
class Example {
  /// Documentation for field.
  final String field;
  
  const Example({required this.field});
  
  factory Example.fromJson(Map<String, dynamic> json) => _$ExampleFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExampleToJson(this);
}
```

After creating or modifying serializable classes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Working with the Code

### Common Commands

```bash
# Generate serialization code
dart run build_runner build --delete-conflicting-outputs

# Format code
dart format .

# Analyze code
dart analyze

# Run tests (if available)
flutter test
```

### Type Conventions
- **Colors**: Use `int` type (e.g., `0xFF000000`)
- **URLs**: Use `String` with `Url` suffix (e.g., `loaderIconUrl`)
- **Mixed types**: Create dedicated classes for fields that can be color or image:
  ```dart
  class ColorOrImage {
    final int? color;
    final String? imageUrl;
  }
  ```

### Naming Conventions (Following Effective Dart)
- **Classes**: `UpperCamelCase` (e.g., `ReclaimAppTheme`)
- **Enums**: Use descriptive, unique names in `UpperCamelCase` (e.g., `ReclaimAppThemeMode`)
- **Files**: `lowercase_with_underscores` (e.g., `reclaim_app_theme.dart`)
- **Variables/Methods**: `lowerCamelCase` (e.g., `loaderIconUrl`)
- **Constants**: PREFER `lowerCamelCase` (e.g., `defaultTimeout`)
- **URL fields**: Must end with `Url` suffix
- **Icon fields**: Must include `Icon` in the name

## Common Patterns

### Override System
Classes extending `ReclaimOverride<T>` are part of the override system for customization.

### Caching Pattern
Static caching is used throughout:
```dart
static final _cachedAppInfo = <String, AppInfo>{};
```

### Factory Methods
- Use `fromJson` factories for deserialization
- Static methods like `fromAppId` for async initialization

### CopyWith Pattern
Implement `copyWith` for immutable updates:
```dart
AppInfo copyWith({String? appName, String? appImage}) {
  return AppInfo(
    appName: appName ?? this.appName,
    appImage: appImage ?? this.appImage,
  );
}
```

## Key Dependencies

- `json_annotation` & `json_serializable` - JSON serialization
- `flutter_inappwebview` - WebView functionality
- `http` - HTTP client (preferred over dio)
- `ReclaimHttpClient` - Custom HTTP client with caching and retry logic (preferred)
- `flutter_secure_storage` - Secure storage
- `shared_preferences` - Local storage

## Important Guidelines

1. **Follow Architecture** - Review and follow `docs/ARCHITECTURE.md` for architectural patterns and guidelines
2. **Follow Effective Dart** - Strictly adhere to https://dart.dev/effective-dart
3. **Use ReclaimHttpClient** - Prefer the custom HTTP client for reliability and performance
4. **Avoid dio** - The dio package is being phased out, use http package or ReclaimHttpClient instead
5. **Never use freezed** - This project uses json_serializable exclusively
6. **Check existing patterns** - Follow established code patterns before implementing new features
7. **Maintain consistency** - Match the existing code style and structure
8. **Document public APIs** - All public members need dartdoc comments following Effective Dart style
9. **Handle null safety** - Use nullable types appropriately
10. **Generated files** - Never manually edit `.g.dart` files
11. **Prefer const constructors** - Use `const` constructors where possible

## Making Changes

When making changes:
1. Review `docs/ARCHITECTURE.md` for architectural patterns
2. Review [Effective Dart](https://dart.dev/effective-dart) guidelines
3. Understand the existing pattern in similar files
4. Make your changes following those patterns
5. Use ReclaimHttpClient or http package for HTTP requests (not dio)
6. Run code generation if needed
7. Format your code with `dart format`
8. Ensure all analysis passes with `dart analyze`
9. Test your changes in the example app if applicable

## Code Quality Checklist

Before submitting changes, ensure:
- [ ] Code follows Effective Dart guidelines
- [ ] HTTP requests use ReclaimHttpClient or http package (not dio)
- [ ] All public APIs have dartdoc comments
- [ ] Code is formatted with `dart format`
- [ ] `dart analyze` shows no issues
- [ ] Generated code is up to date
- [ ] Naming conventions are followed
- [ ] Existing patterns are maintained
