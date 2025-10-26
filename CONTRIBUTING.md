# Contributing to MyCloud

Thank you for considering contributing to MyCloud! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (OS, versions, etc.)
- **Logs or screenshots** if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide detailed description** of the proposed feature
- **Explain why this enhancement would be useful**
- **List any alternatives** you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Commit with clear messages** describing what and why
6. **Push to your fork** and submit a pull request

#### Pull Request Process

1. Update the README.md with details of changes if needed
2. Ensure all tests pass and code follows style guidelines
3. Get approval from at least one maintainer
4. Squash commits if requested
5. Your PR will be merged by a maintainer

## Development Setup

### Prerequisites

```bash
# Install required tools
terraform --version  # >= 1.0
go version          # >= 1.23
node --version      # >= 16
python3 --version   # >= 3.9
```

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/level3_cloud_track.git
cd level3_cloud_track

# Create a branch
git checkout -b feature/your-feature-name

# Make changes and test
# ...

# Commit changes
git add .
git commit -m "Add: your feature description"

# Push to your fork
git push origin feature/your-feature-name
```

## Code Style Guidelines

### Go (Backend API)

- Follow [Effective Go](https://golang.org/doc/effective_go.html)
- Use `gofmt` for formatting
- Add comments for exported functions
- Handle errors explicitly

```go
// Good
func CreateDatabase(name string) error {
    if name == "" {
        return errors.New("database name is required")
    }
    // ...
}

// Bad
func CreateDatabase(name string) {
    // Missing error handling
}
```

### Python (PostgreSQL API)

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where applicable
- Add docstrings to functions
- Use `black` for formatting

```python
# Good
def create_database(name: str, owner: str) -> dict:
    """
    Create a new PostgreSQL database.
    
    Args:
        name: Database name
        owner: Database owner username
        
    Returns:
        Database configuration dictionary
    """
    pass
```

### JavaScript/Vue.js (Frontend)

- Follow [Vue.js Style Guide](https://vuejs.org/style-guide/)
- Use ES6+ features
- Add JSDoc comments for complex functions
- Use Prettier for formatting

```javascript
// Good
/**
 * Fetch databases from API
 * @returns {Promise<Array>} List of databases
 */
async function fetchDatabases() {
    const response = await api.get('/api/v1/databases');
    return response.data;
}
```

### Terraform (Infrastructure)

- Use consistent naming conventions
- Add descriptions to all variables
- Group related resources together
- Use modules for reusability

```hcl
# Good
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-cluster"
}
```

## Testing

### Backend API (Go)

```bash
cd paas-api
go test ./...
go test -race ./...
```

### Frontend (Vue.js)

```bash
cd front/paas-frontend
npm run test:unit
npm run lint
```

### Infrastructure (Terraform)

```bash
cd terraform
terraform fmt -check
terraform validate
terraform plan
```

## Commit Message Guidelines

Use clear and meaningful commit messages:

```
<type>: <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Formatting, missing semicolons, etc.
- **refactor**: Code restructuring
- **test**: Adding tests
- **chore**: Maintenance tasks

### Examples

```
feat: Add database metrics endpoint

Implement /api/v1/databases/{id}/metrics endpoint
to fetch CPU and memory usage from Prometheus

Closes #123
```

```
fix: Resolve CORS issue in production

Update allowed origins to include production domain
in API CORS configuration

Fixes #456
```

## Documentation

- Update README.md for user-facing changes
- Add inline comments for complex logic
- Update API documentation for endpoint changes
- Include examples in documentation

## Security

- **Never commit sensitive data** (passwords, API keys, tokens)
- Use environment variables for secrets
- Review security implications of changes
- Report security vulnerabilities privately

See [SECURITY.md](SECURITY.md) for detailed security guidelines.

## Questions?

Feel free to:
- Open an issue for discussion
- Ask in pull request comments
- Contact maintainers directly

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to MyCloud! 🚀
