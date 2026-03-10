# QuantumFinOps CI/CD Workflows

## 🔄 Automated Workflows

### 1. **terraform-ci.yml** - Terraform CI/CD Pipeline
Runs on every push to `main` and all PRs

**Jobs:**
- 🔍 **Validate** - Format check, init, validate
- 🔒 **Security Scan** - Checkov + tfsec
- 📋 **Plan** - Generate and comment Terraform plan (PRs only)
- 💰 **Cost Estimation** - Infracost analysis (PRs only)
- 📝 **README Update** - Auto-update status badges
- 📢 **Notify** - Success notifications

### 2. **python-lint.yml** - Python Code Quality
Runs on Lambda function changes

**Checks:**
- Black formatter
- Flake8 linting
- Pylint analysis

### 3. **auto-label.yml** - Automatic PR Labeling
Labels PRs based on files changed:
- `terraform` - Infrastructure changes
- `lambda` - Function code
- `documentation` - Markdown files
- `security` - Security-related changes
- Size labels: XS, S, M, L, XL, XXL

## 🔐 Required Secrets

Add these in GitHub Settings → Secrets:
```bash
AWS_ACCESS_KEY_ID       # AWS credentials
AWS_SECRET_ACCESS_KEY   # AWS credentials
INFRACOST_API_KEY       # Optional: Cost estimation
```

## 🚀 Usage

### Automatic on Push:
```bash
git push origin main
# Triggers: Terraform CI, Python lint, README update
```

### Automatic on PR:
```bash
gh pr create
# Triggers: Validation, security scan, plan, cost estimate, auto-label
```

## 📊 Status Badges

Add to README:
```markdown
![Terraform CI](https://github.com/ccarrylab/quantum-finops-platform/workflows/QuantumFinOps%20Terraform%20CI%2FCD/badge.svg)
![Python Lint](https://github.com/ccarrylab/quantum-finops-platform/workflows/Python%20Linting/badge.svg)
```

## 🎯 Best Practices

1. **Always create PRs** for infrastructure changes
2. **Review cost estimates** before merging
3. **Fix security findings** before deployment
4. **Keep Terraform formatted** (`terraform fmt`)
