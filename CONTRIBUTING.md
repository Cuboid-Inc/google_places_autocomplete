# Contributing to Google Places Autocomplete

Thank you for your interest in contributing to this package! This document provides guidelines and instructions for contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/google_places_autocomplete.git
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode for native development
- A Google Places API key for testing

### Running the Example App

```bash
cd example
flutter pub get
flutter run
```

### Running Tests

```bash
flutter test
```

### Running Analysis

```bash
flutter analyze
dart format --set-exit-if-changed .
```

## Code Guidelines

### Dart Code

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `dart format` to format code
- Add DartDoc comments to all public APIs
- Include code examples in documentation where helpful
- Use `const` constructors where possible

### Native Code (Android/iOS)

- **Android (Kotlin)**: Follow [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html)
- **iOS (Swift)**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

### Testing

- Add tests for new features
- Ensure existing tests pass before submitting
- Aim for 80%+ code coverage

## Pull Request Process

1. **Update documentation** if you're changing behavior
2. **Add tests** for new functionality
3. **Update CHANGELOG.md** with your changes
4. **Run all checks** before submitting:
   ```bash
   flutter analyze
   flutter test
   dart format --set-exit-if-changed .
   ```
5. **Submit your PR** with a clear description of changes

## Commit Messages

Use clear, descriptive commit messages:

- `feat: add error callback for handling API failures`
- `fix: iOS distance returning 0 instead of null`
- `docs: update README with new API parameters`
- `test: add unit tests for Prediction model`

## Reporting Issues

When reporting issues, please include:

- Flutter version (`flutter --version`)
- Package version
- Platform (Android/iOS)
- Steps to reproduce
- Expected vs actual behavior
- Error logs if applicable

## Questions?

Feel free to open an issue for questions or discussions about the package.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
