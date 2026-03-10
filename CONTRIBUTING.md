# Contributing to QuantumFinOps

Thank you for your interest in contributing to QuantumFinOps!

## How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**
   ```bash
   pytest tests/ -v
   ```
5. **Commit your changes**
   ```bash
   git commit -m "Add: description of your changes"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

## Code Standards

### Python
- Follow PEP 8 style guide
- Add docstrings to functions
- Include type hints where appropriate
- Write unit tests for new features

### Terraform
- Run `terraform fmt` before committing
- Validate with `terraform validate`
- Include examples in module documentation
- Follow HashiCorp naming conventions

### Testing
- All tests must pass before PR is merged
- Add tests for new features
- Maintain >80% code coverage

## Questions?

- Open an issue for bugs or feature requests
- Email: cohen.carryl@gmail.com
- LinkedIn: linkedin.com/in/cohencarryl

## Code of Conduct

Be respectful, professional, and collaborative.
