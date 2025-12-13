# Nexus EKS Cluster - Infraestrutura como Código

Infraestrutura AWS EKS completa seguindo as melhores práticas do mercado.

## 📋 Visão Geral

Este projeto provisiona uma infraestrutura EKS completa na AWS com:
- ✅ Cluster EKS altamente disponível
- ✅ VPC com subnets públicas e privadas
- ✅ Managed Node Groups com auto-scaling
- ✅ IAM Roles for Service Accounts (IRSA)
- ✅ Observabilidade (Prometheus + Grafana)
- ✅ Kubernetes Dashboard
- ✅ Ingress Controller
- ✅ Backup e recuperação de estado

## 🏗️ Arquitetura
┌─────────────────────────────────────────────────────────┐
│ AWS Account │
│ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ VPC │ │
│ │ ┌─────────────┐ ┌─────────────┐ │ │
│ │ │ Public │ │ Private │ │ │
│ │ │ Subnets │ │ Subnets │ │ │
│ │ └──────┬──────┘ └──────┬──────┘ │ │
│ │ │ │ │ │
│ │ ┌──────▼──────┐ ┌──────▼──────┐ │ │
│ │ │ IGW │ │ NAT GW │ │ │
│ │ └─────────────┘ └─────────────┘ │ │
│ │ │ │ │ │
│ │ ┌──────▼────────────────▼──────┐ │ │
│ │ │ EKS Cluster │ │ │
│ │ │ ┌─────────────────────┐ │ │ │
│ │ │ │ Control Plane │ │ │ │
│ │ │ └─────────────────────┘ │ │ │
│ │ │ │ │ │
│ │ │ ┌─────────────────────┐ │ │ │
│ │ │ │ Worker Nodes │ │ │ │
│ │ │ │ • Managed Groups │ │ │ │
│ │ │ │ • Auto-scaling │ │ │ │
│ │ │ └─────────────────────┘ │ │ │
│ │ └──────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘


## 🚀 Quick Start

### Pré-requisitos

1. **AWS CLI** configurado
2. **Terraform** >= 1.5.0
3. **kubectl** >= 1.28
4. **helm** >= 3.10

### Deploy para ambiente DEV

```bash
# Clone o repositório
git clone https://github.com/seu-org/aws-eks-nexus.git
cd aws-eks-nexus

# Configure credenciais AWS
export AWS_PROFILE=nexus-dev

# Execute deploy completo
make deploy ENVIRONMENT=dev

# Ou passo a passo:
make init ENVIRONMENT=dev
make plan ENVIRONMENT=dev
make apply ENVIRONMENT=dev
make kubeconfig ENVIRONMENT=dev