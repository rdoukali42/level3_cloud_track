# MyCloud - Cloud-Native Database-as-a-Service Platform

> **Arkadia LEVEL3 Program - In collaboration with STACKIT**
> This project was developed as part of the **Arkadia LEVEL3 Cloud Track** in collaboration with **STACKIT**.
> Not intended for production use as-is.

A PaaS portal for provisioning and managing PostgreSQL databases on Kubernetes. Users authenticate via OAuth, request database instances through a REST API, and the platform handles the full lifecycle on K3s. Infrastructure provisioned with Terraform on OpenStack, backend in Go with JWT auth via ZITADEL, frontend in Vue.js with OIDC login, and Prometheus monitoring with CPU-based autoscaling.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                            │
│                    Vue.js Frontend (Port 8086)                   │
│                    + ZITADEL OAuth Integration                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/REST
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                           │
│               Go REST API (NodePort 30081)                       │
│                   + JWT Authentication                           │
│                   + Database Management                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓
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
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                 Infrastructure Layer (OpenStack)                 │
│         Master Nodes + Worker Nodes + Networking                 │
│              Provisioned via Terraform                           │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
myCloud/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── providers.tf
│   └── modules/
│       ├── cluster/               # OpenStack VMs, networking, K3s
│       └── k8s-apps/              # PostgreSQL, Prometheus deployments
├── paas-api/
│   ├── main.go                    # Go API with JWT auth
│   ├── go.mod
│   └── Dockerfile
├── paas-postgresql/
│   └── api/
│       └── app.py                 # Flask DB provisioner
├── front/paas-frontend/
│   └── src/
│       ├── App.vue
│       ├── components/
│       │   └── DatabaseManager.vue
│       └── services/
│           ├── auth.js            # OIDC
│           └── api.js
├── paas-manifests/
│   ├── paas-api-deployment.yaml
│   ├── paas-api-service.yaml
│   └── nginx-config.yaml
└── scripts/
    ├── cluster_init.sh
    └── setup_k3s_kubeconfig.sh
```

## How to Run

```bash
git clone https://github.com/rdoukali42/level3_cloud_track.git
cd level3_cloud_track
cp .env.example .env
cp paas-api/.env.example paas-api/.env
cp front/paas-frontend/.env.example front/paas-frontend/.env
```

### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
export KUBECONFIG=/path/to/kubeconfig
```

### 2. Run the API

```bash
cd paas-api
go mod download
go build -o paas-api .

export POSTGRES_DSN="postgres://user:pass@postgresql.default.svc.cluster.local:5432/db?sslmode=disable"
export ZITADEL_ISSUER="https://your-instance.zitadel.cloud"
export ZITADEL_API_CLIENT_ID="your-client-id"
export ALLOWED_ORIGINS="http://localhost:8086"

./paas-api
```

Or deploy to Kubernetes:

```bash
kubectl apply -f ../paas-manifests/
```

### 3. Run the Frontend

```bash
cd front/paas-frontend
npm install
npm run serve
# Access at http://localhost:8086
```

### Test the API

```bash
TOKEN="your-jwt-token-from-frontend"

curl -H "Authorization: Bearer $TOKEN" http://localhost:30081/api/v1/databases

curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Name": "testdb"}' \
  http://localhost:30081/api/v1/databases
```

### Access Monitoring

```bash
# Prometheus UI
http://\<master-node-ip\>:30090
```

---

**Reda Doukali**
[github.com/rdoukali42](https://github.com/rdoukali42) | [linkedin.com/in/reda-doukali](https://linkedin.com/in/reda-doukali)
