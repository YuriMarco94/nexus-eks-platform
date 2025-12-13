# Nexus EKS Cluster - Infraestrutura como Código

Infraestrutura AWS EKS completa seguindo as melhores práticas do mercado.

Infrastructure as Code platform for AWS EKS with Terraform and GitHub Actions CI/CD.

## 📋 Features

- ✅ **Multi-environment** (dev, staging, prod)
- ✅ **GitHub Actions CI/CD** with automated deployments
- ✅ **Modular Terraform** architecture
- ✅ **Kubernetes manifests** with Kustomize
- ✅ **Security best practices** (IAM, Security Groups)
- ✅ **Monitoring** (CloudWatch, optional Prometheus)
- ✅ **Automated backups** with Terraform state locking

## 🏗️ Architecture
┌─────────────────────────────────────────────────────────────┐
│ GitHub Repository │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │ Terraform │ │ K8s YAML │ │ Workflows │ │
│ │ Code │ │ Manifests │ │ (CI/CD) │ │
│ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ │
└─────────┼─────────────────┼──────────────────┼──────────────┘
│ │ │
▼ ▼ ▼
┌─────────┼─────────────────┼──────────────────┼──────────────┐
│ GitHub Actions Runner │ │ │
│ ┌───────────────────────▼──────────────────▼────────────┐ │
│ │ Terraform Apply │ │
│ └───────────────────────────┬───────────────────────────┘ │
└──────────────────────────────┼──────────────────────────────┘
▼
┌─────────────────────┐
│ AWS Cloud │
│ ┌──────────────┐ │
│ │ EKS │ │
│ │ Cluster │ │
│ └──────────────┘ │
└─────────────────────┘

## 🚀 Quick Start

### Prerequisites

- **AWS Account** with appropriate permissions
- **AWS CLI** configured (`aws configure --profile nexus-alpha`)
- **Terraform** (>= 1.9.0)
- **kubectl** and **helm**
- **GitHub Repository** with secrets configured

### Local Deployment

```bash
# Clone repository
git clone https://github.com/YOUR_USER/nexus-eks-platform.git
cd nexus-eks-platform

# Initialize Terraform
make init

# Plan changes
make plan

# Apply infrastructure
make apply

# Configure kubectl
make kube-config

# Verify cluster
make kube-nodes