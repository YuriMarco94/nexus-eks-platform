.PHONY: help init plan apply destroy validate fmt lint test clean

ENVIRONMENT ?= dev
TF_DIR := terraform/environments/$(ENVIRONMENT)

help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Inicializa Terraform
	@echo "Inicializando Terraform para ambiente: $(ENVIRONMENT)"
	cd $(TF_DIR) && terraform init -upgrade -reconfigure

validate: ## Valida configuração Terraform
	@echo "Validando Terraform..."
	cd $(TF_DIR) && terraform validate

plan: validate ## Gera plano de execução
	@echo "Gerando plano para ambiente: $(ENVIRONMENT)"
	cd $(TF_DIR) && terraform plan -out=tfplan

apply: ## Aplica configuração Terraform
	@echo "Aplicando configuração para ambiente: $(ENVIRONMENT)"
	cd $(TF_DIR) && terraform apply -auto-approve

destroy: ## Destrói infraestrutura
	@echo "Destruindo ambiente: $(ENVIRONMENT)"
	cd $(TF_DIR) && terraform destroy -auto-approve

fmt: ## Formata código Terraform
	@echo "Formatando arquivos Terraform..."
	terraform fmt -recursive

lint: ## Executa linter Terraform
	@echo "Executando tflint..."
	terraform fmt -check
	tflint --recursive

test: ## Executa testes
	@echo "Executando testes..."
	cd $(TF_DIR) && terraform plan -detailed-exitcode

kubeconfig: ## Configura kubectl
	@echo "Configurando kubectl..."
	./scripts/deploy.sh $(ENVIRONMENT) --kubeconfig-only

deploy: ## Deploy completo (Terraform + Kubernetes)
	@echo "Executando deploy completo..."
	./scripts/deploy.sh $(ENVIRONMENT)

health: ## Health check do cluster
	@echo "Executando health check..."
	kubectl cluster-info
	kubectl get nodes
	kubectl get pods -A

clean: ## Limpa arquivos temporários
	@echo "Limpando arquivos..."
	find . -name "*.tfstate*" -type f -delete
	find . -name "*.tfplan" -type f -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "terraform.tfstate.backup" -type f -delete

docs: ## Gera documentação
	@echo "Gerando documentação..."
	terraform-docs markdown table ./terraform > ./docs/terraform.md

all: init validate plan apply deploy ## Executa pipeline completo

# Alias
setup: init
up: apply
down: destroy
config: kubeconfig