#!/bin/bash
# Script para destruir ambiente EKS

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ENVIRONMENT=${1:-dev}
TF_DIR="terraform/environments/${ENVIRONMENT}"

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

destroy_kubernetes_resources() {
    print_warn "Removendo recursos Kubernetes..."
    
    kubectl delete --all -A --wait=false --timeout=30s || true
    sleep 10
    
    print_info "Recursos Kubernetes removidos."
}

destroy_terraform() {
    print_warn "Destruindo infraestrutura Terraform..."
    
    cd "$TF_DIR"
    terraform destroy -auto-approve
    
    print_info "Infraestrutura destruída."
}

cleanup_local_files() {
    print_info "Limpando arquivos locais..."
    
    rm -f "$TF_DIR"/tfplan
    rm -f "$TF_DIR"/terraform.tfstate*
    rm -f "$TF_DIR"/.terraform.lock.hcl
    
    print_info "Arquivos locais limpos."
}

main() {
    print_warn "==========================================="
    print_warn "  DESTRUINDO AMBIENTE: $ENVIRONMENT"
    print_warn "==========================================="
    
    read -p "Tem certeza que deseja destruir o ambiente $ENVIRONMENT? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_info "Operação cancelada."
        exit 0
    fi
    
    destroy_kubernetes_resources
    destroy_terraform
    cleanup_local_files
    
    print_info "Ambiente $ENVIRONMENT destruído com sucesso."
}

main "$@"