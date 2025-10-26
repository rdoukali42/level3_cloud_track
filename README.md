# MyCloud - Cloud-Native Database-as-a-Service Platform

> **⚠️ Educational Project Notice**  
> This project was developed as part of the ** Arkadia LEVEL3 Cloud Track** program in collaboration with **STACKIT**.  
> **This is a learning and demonstration project, NOT intended for production use.**  
> It showcases cloud infrastructure concepts, DevOps practices, and platform engineering skills.

A Platform-as-a-Service (PaaS) demonstration project for deploying and managing PostgreSQL databases on Kubernetes, featuring OAuth authentication, automated infrastructure provisioning with Terraform, and a modern Vue.js frontend.

## 🎯 Project Overview

MyCloud is an educational cloud infrastructure project developed for the **Arkadia LEVEL3 program** that demonstrates enterprise-level DevOps practices by combining infrastructure-as-code, container orchestration, and modern web development. 

**Learning Objectives:**
- Infrastructure as Code with Terraform and OpenStack
- Kubernetes cluster management with K3s
- RESTful API development with authentication
- Full-stack application deployment
- DevOps and cloud platform engineering

**The platform demonstrates:**

- **Deploy PostgreSQL instances** dynamically through a REST API
- **Manage database lifecycle** (create, list, delete) via authenticated endpoints
- **Secure access** with OAuth 2.0 / OIDC using ZITADEL
- **Auto-scale** PostgreSQL deployments based on CPU utilization
- **Monitor infrastructure** with Prometheus and Node Exporter

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                            │
│                    Vue.js Frontend (Port 8086)                   │
│                    + ZITADEL OAuth Integration                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/REST
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                           │
│               Go REST API (NodePort 30081)                       │
│                   + JWT Authentication                           │
│                   + Database Management                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster (K3s)                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │   PostgreSQL     │  │   Prometheus     │  │ Node Exporter│  │
│  │   Deployment     │  │   Monitoring     │  │  Metrics     │  │
│  │   + HPA          │  │   (Port 30090)   │  │              │  │
│  │   (Port 30080)   │  └──────────────────┘  └──────────────┘  │
│  └──────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Infrastructure Layer (OpenStack)                 │
│         Master Nodes + Worker Nodes + Networking                 │
│              Provisioned via Terraform                           │
└─────────────────────────────────────────────────────────────────┘
```

## 🌟 Key Features Demonstrated

> **Note:** These features are implemented for educational demonstration. Production deployment would require additional security hardening, error handling, and scalability improvements.

### Infrastructure as Code
- **Terraform modules** for reproducible infrastructure (educational implementation)
- **Modular design** separating cluster provisioning and Kubernetes apps
- **OpenStack integration** for cloud resource management
- **Multi-node K3s cluster** with automated setup

### Security & Authentication
- **OAuth 2.0 / OIDC** integration with ZITADEL (demo configuration)
- **JWT-based authentication** for API endpoints
- **RBAC** in Kubernetes for resource access control
- **Environment-based configuration** to protect secrets

### Database Management
- **Dynamic PostgreSQL provisioning** via REST API (prototype implementation)
- **Horizontal Pod Autoscaling (HPA)** based on CPU metrics
- **Persistent storage** with StatefulSets
- **Database lifecycle management** (create, list, delete)

### Monitoring & Observability
- **Prometheus** for metrics collection
- **Node Exporter** for system-level metrics
- **HPA metrics** for auto-scaling decisions

## 📋 Prerequisites

### Required Software
- **Terraform** >= 1.0
- **kubectl** >= 1.20
- **Go** >= 1.23 (for building the API)
- **Node.js** >= 16 (for the frontend)
- **OpenStack** account with API access

### Required Accounts
- **ZITADEL** instance for OAuth authentication
  - Create an API application for the backend
  - Create a Web application for the frontend

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/rdoukali42/level3_cloud_track.git
cd level3_cloud_track
```

### 2. Configure Environment Variables

```bash
# Copy example environment files
cp .env.example .env
cp paas-api/.env.example paas-api/.env
cp front/paas-frontend/.env.example front/paas-frontend/.env

# Edit each .env file with your credentials
# - OpenStack credentials
# - ZITADEL OAuth details
# - PostgreSQL passwords
```

### 3. Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply infrastructure
terraform apply

# Export kubeconfig
export KUBECONFIG=/path/to/kubeconfig
```

### 4. Deploy the API

```bash
cd ../paas-api

# Install Go dependencies
go mod download

# Build the API
go build -o paas-api .

# Set environment variables (or use .env file)
export POSTGRES_DSN="postgres://myuser:mypassword@postgresql.default.svc.cluster.local:5432/mydb?sslmode=disable"
export ZITADEL_ISSUER="https://your-instance.zitadel.cloud"
export ZITADEL_API_CLIENT_ID="your-api-client-id"
export ALLOWED_ORIGINS="http://localhost:8086"

# Run the API
./paas-api
```

**Or deploy to Kubernetes:**

```bash
kubectl apply -f ../paas-manifests/
```

### 5. Run the Frontend

```bash
cd ../front/paas-frontend

# Install dependencies
npm install

# Start development server
npm run serve

# Access at http://localhost:8086
```

## 📁 Project Structure

```
myCloud/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Root Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── providers.tf               # Cloud provider configuration
│   ├── modules/
│   │   ├── cluster/               # OpenStack cluster module
│   │   │   ├── main.tf           # VM instances, networking, K3s
│   │   │   ├── variables.tf      # Cluster variables
│   │   │   └── outputs.tf        # Cluster outputs
│   │   └── k8s-apps/              # Kubernetes apps module
│   │       ├── main.tf           # PostgreSQL, Prometheus deployments
│   │       ├── variables.tf      # App variables
│   │       └── outputs.tf        # App outputs
│
├── paas-api/                       # Backend API (Go)
│   ├── main.go                    # API server with JWT auth
│   ├── go.mod                     # Go dependencies
│   ├── Dockerfile                 # Container image
│   └── .env.example               # Environment template
│
├── paas-postgresql/                # Python-based DB provisioner
│   └── api/
│       ├── app.py                 # Flask API for DB management
│       └── requirements.txt       # Python dependencies
│
├── front/paas-frontend/            # Frontend (Vue.js)
│   ├── src/
│   │   ├── App.vue               # Main component
│   │   ├── components/
│   │   │   └── DatabaseManager.vue  # DB management UI
│   │   └── services/
│   │       ├── auth.js           # OIDC authentication
│   │       └── api.js            # API client
│   ├── package.json              # Node dependencies
│   └── .env.example              # Frontend environment template
│
├── paas-manifests/                 # Kubernetes manifests
│   ├── paas-api-deployment.yaml   # API deployment
│   ├── paas-api-service.yaml      # API service
│   └── nginx-config.yaml          # Nginx configuration
│
├── scripts/                        # Helper scripts
│   ├── cluster_init.sh            # Cluster initialization
│   ├── setup_k3s_kubeconfig.sh    # Kubeconfig setup
│   └── install_terraform.sh       # Terraform installation
│
├── .gitignore                      # Git ignore rules
├── .env.example                    # Root environment template
└── README.md                       # This file
```

## 🔧 Configuration

### Terraform Variables

Edit `terraform/variables.tf` or use environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ssh_key_name` | SSH keypair name | `k8s-key` |
| `cluster_name` | Cluster identifier | `k8s-cluster` |
| `master_count` | Number of master nodes | `1` |
| `worker_count` | Number of worker nodes | `2` |
| `network_cidr` | Cluster network CIDR | `10.0.0.0/24` |

### API Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_DSN` | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `ZITADEL_ISSUER` | ZITADEL OAuth issuer URL | `https://your-instance.zitadel.cloud` |
| `ZITADEL_API_CLIENT_ID` | API OAuth client ID | `330412688444300258` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:8086` |

### Frontend Environment Variables

| Variable | Description |
|----------|-------------|
| `VUE_APP_ZITADEL_ISSUER` | ZITADEL OAuth issuer |
| `VUE_APP_ZITADEL_CLIENT_ID` | Frontend OAuth client ID |
| `VUE_APP_API_BASE_URL` | Backend API URL |

## 🔐 Security Considerations

### For Public Release ✅

- ✅ All credentials moved to environment variables
- ✅ `.env.example` files provided as templates
- ✅ `.gitignore` configured to exclude sensitive files
- ✅ Terraform state files excluded from repository
- ✅ SSH keys and certificates excluded

### Production Deployment

Before deploying to production:

1. **Use Kubernetes Secrets** for sensitive data
2. **Enable TLS/SSL** for all endpoints
3. **Configure firewall rules** to restrict access
4. **Implement rate limiting** on API endpoints
5. **Enable audit logging** for all database operations
6. **Use managed PostgreSQL** for production databases
7. **Set up backup and disaster recovery**

## 🧪 Testing

### Test the API

```bash
# Get JWT token from frontend after login
TOKEN="your-jwt-token"

# List databases
curl -H "Authorization: Bearer $TOKEN" http://localhost:30081/api/v1/databases

# Create a database
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Name": "testdb"}' \
  http://localhost:30081/api/v1/databases
```

### Access Monitoring

```bash
# Prometheus UI
http://<master-node-ip>:30090

# PostgreSQL (NodePort)
psql -h <master-node-ip> -p 30080 -U myuser -d mydb
```

## 📊 Monitoring

The platform includes built-in monitoring:

- **Prometheus**: Metrics collection and alerting (Port 30090)
- **Node Exporter**: System-level metrics
- **HPA Metrics**: Auto-scaling based on CPU utilization

## 🛠️ Troubleshooting

### Common Issues

**Terraform Apply Fails**
```bash
# Check OpenStack credentials
source openrc.sh
openstack token issue

# Verify Terraform version
terraform version
```

**API Authentication Fails**
```bash
# Verify ZITADEL configuration
# Check that client IDs match in both frontend and backend
# Ensure redirect URIs are correctly configured in ZITADEL
```

**Kubernetes Pods Not Starting**
```bash
# Check pod status
kubectl get pods --all-namespaces

# View pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>
```

## 🤝 Contributing

This is an educational project created for the Arkadia LEVEL3 program. While it's not actively maintained for production use, feedback and suggestions for learning improvements are welcome!

If you're working on a similar educational project:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License & Educational Use

This project is part of the ** Arkadia LEVEL3 Cloud Track** curriculum developed in collaboration with **STACKIT**.

**Status:** Educational/Learning Project  
**Purpose:** Demonstration of cloud infrastructure and DevOps concepts  
**Not for Production:** This code is for educational purposes and should not be deployed in production environments without significant security hardening and testing.

## 🎓 About Arkadia LEVEL3

The Arkadia LEVEL3 program is an advanced cloud infrastructure training initiative by  in partnership with STACKIT, focusing on:
- Cloud platform engineering
- Infrastructure automation
- Kubernetes and container orchestration
- DevOps best practices
- Full-stack cloud application development

## 🙏 Acknowledgments

- **Arkadia LEVEL3 Program** for the comprehensive cloud infrastructure training
- **STACKIT** for industry collaboration and cloud platform expertise
- **ZITADEL** for OAuth/OIDC authentication services
- **K3s** for lightweight Kubernetes
- **Prometheus** for monitoring capabilities

## 📧 Contact

**Author**: Reda Doukali  
**GitHub**: [@rdoukali42](https://github.com/rdoukali42)  
**Repository**: [level3_cloud_track](https://github.com/rdoukali42/level3_cloud_track)  
**Program**:  Arkadia LEVEL3 - Cloud Track

---

**⚠️ Educational Project Disclaimer**

This project was created as part of the ** Arkadia LEVEL3 program** in collaboration with **STACKIT**. It is designed for learning and demonstration purposes only.

**NOT FOR PRODUCTION USE** - This codebase requires significant security hardening, testing, and additional features before being suitable for any production environment. Use at your own risk.

For educational purposes and portfolio demonstration only.
