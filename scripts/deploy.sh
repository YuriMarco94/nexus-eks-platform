#!/bin/bash
# Script de deploy profissional para EKS

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform/environments/${ENVIRONMENT}"
K8S_DIR="${SCRIPT_DIR}/../kubernetes"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    local deps=("terraform" "aws" "kubectl" "helm")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep não encontrado. Por favor, instale primeiro."
            exit 1
        fi
    done
    print_info "Dependências verificadas com sucesso."
}

terraform_init() {
    print_info "Inicializando Terraform para ambiente: $ENVIRONMENT"
    cd "$TF_DIR"
    
    terraform init -upgrade -reconfigure
    terraform validate
    
    print_info "Terraform inicializado com sucesso."
}

terraform_plan() {
    print_info "Gerando plano de execução..."
    terraform plan -out=tfplan
    
    print_info "Plano salvo em tfplan"
}

terraform_apply() {
    print_info "Aplicando configuração do Terraform..."
    
    if [[ -f "tfplan" ]]; then
        terraform apply "tfplan"
    else
        terraform apply -auto-approve
    fi
    
    print_info "Infraestrutura aplicada com sucesso."
}

configure_kubectl() {
    print_info "Configurando kubectl..."
    
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    AWS_REGION=$(terraform output -raw region)
    
    aws eks update-kubeconfig \
        --name "$CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --alias "nexus-$ENVIRONMENT"
    
    print_info "kubectl configurado para cluster: $CLUSTER_NAME"
}

deploy_kubernetes_manifests() {
    print_info "Deployando manifestos Kubernetes..."
    
    # Aplicar base
    kubectl apply -k "${K8S_DIR}/base"
    
    # Aplicar overlays específicos do ambiente
    kubectl apply -k "${K8S_DIR}/overlays/${ENVIRONMENT}"
    
    # Deploy addons específicos
    deploy_addons
    
    print_info "Manifestos Kubernetes aplicados."
}

deploy_addons() {
    print_info "Deployando addons..."
    
    # Kubernetes Dashboard
    helm upgrade --install kubernetes-dashboard \
        kubernetes-dashboard/kubernetes-dashboard \
        --namespace kubernetes-dashboard \
        --create-namespace \
        --values "${K8S_DIR}/manifests/dashboard/kubernetes-dashboard-values.yaml" \
        --wait
    
    # Prometheus Stack
    helm upgrade --install monitoring \
        prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --values "${K8S_DIR}/manifests/monitoring/kube-prometheus-stack-values.yaml" \
        --wait
    
    # Ingress Controller
    deploy_ingress_controller
    
    print_info "Addons deployados."
}

deploy_ingress_controller() {
    print_info "Deployando Ingress Controller..."
    
    helm upgrade --install ingress-nginx \
        ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internal \
        --wait
    
    print_info "Ingress Controller deployado."
}

health_check() {
    print_info "Realizando health check..."
    
    # Verificar cluster
    kubectl cluster-info
    
    # Verificar nodes
    kubectl get nodes
    
    # Verificar pods
    kubectl get pods -A
    
    # Verificar services
    kubectl get svc -A
    
    print_info "Health check completado."
}

show_access_info() {
    print_info "=== INFORMAÇÕES DE ACESSO ==="
    
    echo ""
    echo "Cluster: $(kubectl config current-context)"
    echo ""
    
    # Dashboard
    echo "Dashboard:"
    echo "  kubectl proxy &"
    echo "  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    
    # Grafana
    echo "Grafana:"
    echo "  kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"
    echo "  http://localhost:3000 (admin/admin)"
    echo ""
    
    # Prometheus
    echo "Prometheus:"
    echo "  kubectl port-forward svc/monitoring-prometheus-server 9090:80 -n monitoring"
    echo "  http://localhost:9090"
    echo ""
    
    print_info "Deploy completado com sucesso!"
}

# Main execution
main() {
    print_info "Iniciando deploy para ambiente: $ENVIRONMENT"
    
    check_dependencies
    
    # Terraform
    terraform_init
    terraform_plan
    terraform_apply
    
    # Kubernetes
    configure_kubectl
    deploy_kubernetes_manifests
    health_check
    show_access_info
}

# Run main
main "$@"