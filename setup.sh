#!/bin/bash
# Quick Setup Script for MyCloud Project
# This script helps set up the development environment

set -e

echo "🚀 MyCloud Project Setup"
echo "========================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."
echo ""

MISSING_DEPS=0

if ! command_exists terraform; then
    print_error "Terraform is not installed"
    MISSING_DEPS=1
else
    print_info "Terraform: $(terraform version | head -n1)"
fi

if ! command_exists kubectl; then
    print_error "kubectl is not installed"
    MISSING_DEPS=1
else
    print_info "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
fi

if ! command_exists go; then
    print_error "Go is not installed"
    MISSING_DEPS=1
else
    print_info "Go: $(go version)"
fi

if ! command_exists node; then
    print_error "Node.js is not installed"
    MISSING_DEPS=1
else
    print_info "Node.js: $(node --version)"
fi

if ! command_exists python3; then
    print_error "Python3 is not installed"
    MISSING_DEPS=1
else
    print_info "Python3: $(python3 --version)"
fi

echo ""

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Please install missing dependencies before continuing"
    exit 1
fi

# Setup environment files
echo "⚙️  Setting up environment files..."
echo ""

if [ ! -f .env ]; then
    print_info "Creating .env from template"
    cp .env.example .env
    print_warning "Please edit .env with your configuration"
else
    print_info ".env already exists"
fi

if [ ! -f paas-api/.env ]; then
    print_info "Creating paas-api/.env from template"
    cp paas-api/.env.example paas-api/.env
    print_warning "Please edit paas-api/.env with your configuration"
else
    print_info "paas-api/.env already exists"
fi

if [ ! -f front/paas-frontend/.env ]; then
    print_info "Creating frontend .env from template"
    cp front/paas-frontend/.env.example front/paas-frontend/.env
    print_warning "Please edit front/paas-frontend/.env with your configuration"
else
    print_info "front/paas-frontend/.env already exists"
fi

if [ ! -f terraform/terraform.tfvars ]; then
    print_info "Creating terraform.tfvars from template"
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    print_warning "Please edit terraform/terraform.tfvars with your configuration"
else
    print_info "terraform/terraform.tfvars already exists"
fi

echo ""

# Install dependencies
echo "📦 Installing dependencies..."
echo ""

# Go dependencies
if [ -f paas-api/go.mod ]; then
    print_info "Installing Go dependencies..."
    cd paas-api
    go mod download
    cd ..
fi

# Node dependencies
if [ -f front/paas-frontend/package.json ]; then
    print_info "Installing Node.js dependencies..."
    cd front/paas-frontend
    npm install
    cd ../..
fi

# Python dependencies
if [ -f paas-postgresql/api/requirements.txt ]; then
    print_info "Installing Python dependencies..."
    pip3 install -r paas-postgresql/api/requirements.txt
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Configure your environment files:"
echo "   - Edit .env"
echo "   - Edit paas-api/.env"
echo "   - Edit front/paas-frontend/.env"
echo "   - Edit terraform/terraform.tfvars"
echo ""
echo "2. Set up ZITADEL OAuth:"
echo "   - Create ZITADEL instance at https://zitadel.com"
echo "   - Create API application and Frontend application"
echo "   - Add client IDs to .env files"
echo ""
echo "3. Deploy infrastructure:"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "4. Run the application:"
echo "   - API: cd paas-api && go run main.go"
echo "   - Frontend: cd front/paas-frontend && npm run serve"
echo ""
echo "📖 For detailed instructions, see README.md"
echo ""
