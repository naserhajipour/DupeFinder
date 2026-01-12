# Contributing to DupeFinder

Thank you for your interest in contributing to DupeFinder.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install dependencies: `cpanm --installdeps .`
4. Create a feature branch: `git checkout -b feature/your-feature`

## Development

### Code Style

* Use `strict` and `warnings` in all Perl files
* Follow existing code formatting
* Keep functions focused and modular
* Add POD documentation for public methods

### Testing

Run the test suite before submitting:

```bash
prove -l t/
```

Add tests for new functionality in the `t/` directory.

### Commit Messages

* Use clear, descriptive commit messages
* Start with a verb (Add, Fix, Update, Remove)
* Keep the first line under 72 characters

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Submit PR against the `main` branch
4. Describe your changes in the PR description

## Reporting Issues

* Check existing issues before creating a new one
* Include Perl version and OS information
* Provide steps to reproduce the issue
* Include relevant error messages

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
