# =========================================
# BOOTSTRAP PLATFORM: Monitoring + CI/CD
# - Idempotente
# - Faz backup antes de sobrescrever
# - Branches: develop (auto), master (somente PR/plan)
# =========================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ====== AJUSTE AQUI SE PRECISAR ======
$RepoRoot = "C:\Users\Yuri\nexus-eks-platform"
$AwsRegion = "us-east-1"
$ClusterDev = "Nexus-dev"
$ClusterProd = "Nexus-prod"   # se não existir ainda, ok (workflow prod fica pronto)
$TerraformDevDir = "terraform/environments/dev"
$TerraformProdDir = "terraform/environments/prod"

# IAM Role que o GitHub Actions vai assumir (criar na AWS na parte B)
$GitHubRoleArn = "arn:aws:iam::597088058179:role/GitHubActions-EKS-Deploy"

# =========================================
function Ensure-Dir($path) {
  if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

function Write-FileSafe($path, $content) {
  $dir = Split-Path $path -Parent
  Ensure-Dir $dir

  $new = ($content -replace "`r?`n","`n")
  if (Test-Path $path) {
    $old = (Get-Content -Raw $path) -replace "`r?`n","`n"
    if ($old -eq $new) {
      Write-Host "UNCHANGED: $path" -ForegroundColor DarkGray
      return
    }
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $path "$path.$ts.bak" -Force
    Write-Host "BACKUP:   $path.$ts.bak" -ForegroundColor Yellow
  }
  Set-Content -Path $path -Value $content -Encoding utf8
  Write-Host "WROTE:    $path" -ForegroundColor Green
}

function Apply-Template($template, $map) {
  $out = $template
  foreach ($k in $map.Keys) { $out = $out.Replace($k, $map[$k]) }
  return $out
}

# =========================================
Set-Location $RepoRoot

Ensure-Dir ".github/workflows"
Ensure-Dir "kubernetes/manifests/monitoring"

# =========================================
# 0) SANITIZE: corrige \${{ ... }} (se sobrou do erro anterior)
# =========================================
Get-ChildItem ".github/workflows" -Filter *.yml -ErrorAction SilentlyContinue | ForEach-Object {
  $p = $_.FullName
  $c = Get-Content -Raw $p
  if ($c -match '\\\$\{\{') {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.$ts.bak" -Force
    $fixed = $c.Replace('\${{','${{')
    Set-Content -Encoding utf8 -Path $p -Value $fixed

    # IMPORTANT: string literal segura pra não quebrar o parse do PowerShell
    Write-Host ('FIXED:   removed \${{ -> ${{ in ' + $p) -ForegroundColor Green
  }
}

# =========================================
# 1) kube-prometheus-stack values
# =========================================
$kpsValues = @"
grafana:
  enabled: true
  defaultDashboardsEnabled: true

  admin:
    existingSecret: grafana-admin
    userKey: admin-user
    passwordKey: admin-password

  service:
    type: LoadBalancer

prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

alertmanager:
  enabled: true
"@
Write-FileSafe "kubernetes/manifests/monitoring/kube-prometheus-stack-values.yaml" $kpsValues

# =========================================
# 2) Terraform PLAN workflow (PR -> master)
# =========================================
$tfPlanTpl = @'
name: Terraform Plan (PR)

on:
  pull_request:
    branches: [ "master" ]
    paths:
      - "terraform/**"

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  AWS_REGION: __AWS_REGION__

jobs:
  plan-dev:
    name: Plan DEV
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
        working-directory: __TF_DEV_DIR__

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: __ROLE_ARN__
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt/validate/plan
        run: |
          terraform fmt -recursive
          terraform init -reconfigure
          terraform validate
          terraform plan -no-color -out=tfplan

  plan-prod:
    name: Plan PROD (if exists)
    if: ${{ hashFiles('__TF_PROD_DIR__/**') != '' }}
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
        working-directory: __TF_PROD_DIR__

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: __ROLE_ARN__
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt/validate/plan
        run: |
          terraform fmt -recursive
          terraform init -reconfigure
          terraform validate
          terraform plan -no-color -out=tfplan
'@

$tfPlan = Apply-Template $tfPlanTpl @{
  "__AWS_REGION__"  = $AwsRegion
  "__ROLE_ARN__"    = $GitHubRoleArn
  "__TF_DEV_DIR__"  = $TerraformDevDir
  "__TF_PROD_DIR__" = $TerraformProdDir   # também entra no hashFiles()
}
Write-FileSafe ".github/workflows/terraform-plan.yml" $tfPlan

# =========================================
# 3) Terraform APPLY DEV workflow (push develop)
# =========================================
$tfApplyDevTpl = @'
name: Terraform Apply DEV (develop)

on:
  push:
    branches: [ "develop" ]
    paths:
      - "terraform/**"

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: __AWS_REGION__

jobs:
  apply-dev:
    name: Apply DEV
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
        working-directory: __TF_DEV_DIR__

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: __ROLE_ARN__
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform init/validate/apply
        run: |
          terraform init -reconfigure
          terraform validate
          terraform apply -auto-approve
'@

$tfApplyDev = Apply-Template $tfApplyDevTpl @{
  "__AWS_REGION__" = $AwsRegion
  "__ROLE_ARN__"   = $GitHubRoleArn
  "__TF_DEV_DIR__" = $TerraformDevDir
}
Write-FileSafe ".github/workflows/terraform-apply-dev.yml" $tfApplyDev

# =========================================
# 4) Deploy K8s DEV workflow (push develop) + Observability
# =========================================
$deployDevTpl = @'
name: Deploy K8s DEV (EKS)

on:
  push:
    branches: [ "develop" ]
    paths:
      - "kubernetes/**"
      - ".github/workflows/deploy-k8s-dev.yml"

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: __AWS_REGION__
  EKS_CLUSTER_NAME: __CLUSTER_DEV__

jobs:
  deploy-dev:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: __ROLE_ARN__
          aws-region: ${{ env.AWS_REGION }}

      - name: Install kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: "v1.30.0"

      - name: Install Helm
        uses: azure/setup-helm@v4
        with:
          version: "v3.15.4"

      - name: Configure kubeconfig
        run: |
          aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME}" --region "${AWS_REGION}"
          kubectl get nodes -o wide

      # ===== Observability: kube-prometheus-stack =====
      - name: Deploy monitoring namespace
        run: |
          kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

      - name: Create/Update Grafana admin secret (from GitHub Secrets)
        run: |
          kubectl -n monitoring create secret generic grafana-admin \
            --from-literal=admin-user="${{ secrets.GRAFANA_ADMIN_USER }}" \
            --from-literal=admin-password="${{ secrets.GRAFANA_ADMIN_PASSWORD }}" \
            --dry-run=client -o yaml | kubectl apply -f -

      - name: Deploy kube-prometheus-stack
        run: |
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          helm repo update
          helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
            -n monitoring \
            -f kubernetes/manifests/monitoring/kube-prometheus-stack-values.yaml

      - name: Wait Grafana
        run: |
          kubectl -n monitoring rollout status deploy/kube-prometheus-stack-grafana --timeout=10m || true
          kubectl -n monitoring get pods

      - name: Print Grafana URL
        run: |
          for i in {1..60}; do
            HOST=$(kubectl -n monitoring get svc kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
            if [ -n "$HOST" ]; then break; fi
            sleep 10
          done
          echo "Grafana URL: http://$HOST"

      # ===== Workloads =====
      - name: Apply base
        run: |
          kubectl apply -k kubernetes/base

      - name: Apply overlays (dev/prod) with LoadRestrictionsNone
        run: |
          kubectl kustomize kubernetes/overlays/dev --load-restrictor LoadRestrictionsNone | kubectl apply -f -
          kubectl kustomize kubernetes/overlays/prod --load-restrictor LoadRestrictionsNone | kubectl apply -f -

      - name: Print Gateway URL and test
        run: |
          GW=$(kubectl -n nginx-gateway get gateway nexus-gw -o jsonpath='{.status.addresses[0].value}')
          echo "Gateway LB: http://$GW"
          curl -I "http://$GW/dev" || true
          curl -I "http://$GW/prod" || true

      - name: Summary
        run: |
          kubectl get ns | egrep "monitoring|demo|nginx-gateway" || true
          kubectl -n monitoring get svc || true
          kubectl get httproute -A || true
'@

$deployDev = Apply-Template $deployDevTpl @{
  "__AWS_REGION__"  = $AwsRegion
  "__ROLE_ARN__"    = $GitHubRoleArn
  "__CLUSTER_DEV__" = $ClusterDev
}
Write-FileSafe ".github/workflows/deploy-k8s-dev.yml" $deployDev

# =========================================
# 5) Deploy K8s PROD (manual + environment approval)
# =========================================
$deployProdTpl = @'
name: Deploy K8s PROD (Manual)

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: __AWS_REGION__
  EKS_CLUSTER_NAME: __CLUSTER_PROD__

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment: prod

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: __ROLE_ARN__
          aws-region: ${{ env.AWS_REGION }}

      - name: Install kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: "v1.30.0"

      - name: Configure kubeconfig
        run: |
          aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME}" --region "${AWS_REGION}"
          kubectl get nodes -o wide

      - name: Apply PROD overlay (LoadRestrictionsNone)
        run: |
          kubectl apply -k kubernetes/base
          kubectl kustomize kubernetes/overlays/prod --load-restrictor LoadRestrictionsNone | kubectl apply -f -

      - name: Summary
        run: |
          kubectl get ns || true
          kubectl get httproute -A || true
'@

$deployProd = Apply-Template $deployProdTpl @{
  "__AWS_REGION__"   = $AwsRegion
  "__ROLE_ARN__"     = $GitHubRoleArn
  "__CLUSTER_PROD__" = $ClusterProd
}
Write-FileSafe ".github/workflows/deploy-k8s-prod.yml" $deployProd

Write-Host "`n✅ OK! Parte A atualizada para develop/master (sem main)." -ForegroundColor Cyan
Write-Host "Próximo passo (Parte B): OIDC Role na AWS + GitHub Secrets (GRAFANA_ADMIN_USER / GRAFANA_ADMIN_PASSWORD)" -ForegroundColor Cyan
