# export-tudo.ps1
# Versao sem acentos para evitar erros de parsing

param(
    [string]$OutputFile = "projeto-completo.yaml"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "EXPORTANDO TODOS OS ARQUIVOS DO PROJETO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Estrutura atualizada detectada" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

# Iniciar conteudo YAML
$yamlContent = "# ===================================================" + [Environment]::NewLine
$yamlContent += "# EXPORTACAO COMPLETA: NEXUS-EKS-PLATFORM" + [Environment]::NewLine
$yamlContent += "# Versao: 2.0 - Estrutura Atualizada" + [Environment]::NewLine
$yamlContent += "# Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" + [Environment]::NewLine
$yamlContent += "# ===================================================" + [Environment]::NewLine + [Environment]::NewLine

$yamlContent += "projeto:" + [Environment]::NewLine
$yamlContent += "  nome: 'nexus-eks-platform'" + [Environment]::NewLine
$yamlContent += "  caminho: '$($PWD.Path -replace '\\', '/')'" + [Environment]::NewLine
$yamlContent += "  data_exportacao: '$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')'" + [Environment]::NewLine
$yamlContent += "  versao_script: '2.0'" + [Environment]::NewLine + [Environment]::NewLine

$arquivosProcessados = 0
$erros = @()

# Funcao para adicionar arquivo ao YAML
function Adicionar-Arquivo {
    param(
        [string]$Caminho,
        [string]$Categoria,
        [string]$Subcategoria = ""
    )
    
    if (-not (Test-Path $Caminho)) {
        $script:erros += "Arquivo nao encontrado: $Caminho"
        return $null
    }
    
    try {
        $conteudo = Get-Content $Caminho -Raw -Encoding UTF8
        $info = Get-Item $Caminho
        
        # Escapar conteudo para YAML
        $conteudoEscapado = $conteudo -replace "'", "''"
        $linhas = $conteudoEscapado -split "`r`n"
        $conteudoYaml = ""
        foreach ($linha in $linhas) {
            $conteudoYaml += "      " + $linha + [Environment]::NewLine
        }
        
        $bloco = "  - categoria: '$Categoria'" + [Environment]::NewLine
        $bloco += "    subcategoria: '$Subcategoria'" + [Environment]::NewLine
        $bloco += "    caminho: '$($Caminho -replace '\\', '/')'" + [Environment]::NewLine
        $bloco += "    tamanho: $($info.Length)" + [Environment]::NewLine
        $bloco += "    modificacao: '$($info.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))'" + [Environment]::NewLine
        $bloco += "    conteudo: |" + [Environment]::NewLine
        $bloco += $conteudoYaml + [Environment]::NewLine
        
        $script:arquivosProcessados++
        return $bloco
        
    } catch {
        $script:erros += "Erro ao ler $Caminho : $_"
        return $null
    }
}

# 1. ARQUIVOS RAIZ
Write-Host "1. Processando arquivos raiz..." -ForegroundColor Green
$yamlContent += "arquivos_raiz:" + [Environment]::NewLine

$arquivosRaiz = @(
    ".gitignore",
    ".tflint.hcl", 
    "LICENSE",
    "Makefile",
    "README.md",
    "projeto-completo.yaml"
)

foreach ($arquivo in $arquivosRaiz) {
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "raiz"
    if ($bloco) {
        $yamlContent += $bloco
    }
}

# 2. GITHUB ACTIONS
Write-Host "2. Processando GitHub Actions..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "github_actions:" + [Environment]::NewLine

$bloco = Adicionar-Arquivo -Caminho ".github/workflows/main-pipeline.yml" -Categoria "ci_cd" -Subcategoria "workflow"
if ($bloco) { $yamlContent += $bloco }

# 3. DOCS
Write-Host "3. Processando Documentacao..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "documentacao:" + [Environment]::NewLine

$docsArquivos = @(
    "docs/PLATFORM-ARCHITECTURE.md"
)

foreach ($arquivo in $docsArquivos) {
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "documentacao" -Subcategoria "arquitetura"
    if ($bloco) { $yamlContent += $bloco }
}

# 4. COMPLIANCE
Write-Host "4. Processando Compliance..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "compliance:" + [Environment]::NewLine

$complianceArquivos = Get-ChildItem -Path "compliance" -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Extension -match '\.(md|yaml|yml|json|txt)$' } |
    ForEach-Object { $_.FullName.Substring($PWD.Path.Length + 1) }

if ($complianceArquivos.Count -eq 0) {
    $yamlContent += "  # Diretorio compliance encontrado mas sem arquivos processaveis" + [Environment]::NewLine
}

foreach ($arquivo in $complianceArquivos) {
    $subcategoria = "policy"
    if ($arquivo -like "*frameworks*") { $subcategoria = "framework" }
    elseif ($arquivo -like "*standards*") { $subcategoria = "standard" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "compliance" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# 5. KUBERNETES
Write-Host "5. Processando Kubernetes..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "kubernetes:" + [Environment]::NewLine

# Lista de todos os arquivos Kubernetes
$k8sArquivos = @(
    "kubernetes/base/kustomization.yaml",
    "kubernetes/manifests/dashboard/kubernetes-dashboard-values.yaml",
    "kubernetes/manifests/gateway/namespace.yaml",
    "kubernetes/manifests/gateway/nginx-config.yaml",
    "kubernetes/manifests/monitoring/kube-prometheus-stack-values.yaml",
    "kubernetes/overlays/dev/kustomization.yaml",
    "kubernetes/overlays/prod/kustomization.yaml",
    "kubernetes/overlays/staging/kustomization.yaml"
)

foreach ($arquivo in $k8sArquivos) {
    $subcategoria = ""
    if ($arquivo -like "*demo*") { $subcategoria = "demo" }
    elseif ($arquivo -like "*gateway*") { $subcategoria = "gateway" }
    elseif ($arquivo -like "*dashboard*") { $subcategoria = "dashboard" }
    elseif ($arquivo -like "*monitoring*") { $subcategoria = "monitoring" }
    elseif ($arquivo -like "*overlays*") { $subcategoria = "overlay" }
    elseif ($arquivo -like "*base*") { $subcategoria = "base" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "kubernetes" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# 6. PLATFORM
Write-Host "6. Processando Platform/IDP..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "platform:" + [Environment]::NewLine

$platformArquivos = @(
    "platform/api/internal-developer-platform.yaml",
    "platform/observability/opentelemetry-collector.yaml",
    "platform/workflows/github-actions-platform.yaml"
)

foreach ($arquivo in $platformArquivos) {
    $subcategoria = ""
    if ($arquivo -like "*api*") { $subcategoria = "api" }
    elseif ($arquivo -like "*observability*") { $subcategoria = "observability" }
    elseif ($arquivo -like "*workflows*") { $subcategoria = "workflows" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "platform" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# 7. SCRIPTS
Write-Host "7. Processando scripts..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "scripts:" + [Environment]::NewLine

$scriptsArquivos = @(
    "scripts/deploy.sh",
    "scripts/destroy.sh"
)

foreach ($arquivo in $scriptsArquivos) {
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "scripts" -Subcategoria ($arquivo -replace ".*/", "")
    if ($bloco) { $yamlContent += $bloco }
}

# 8. SECURITY
Write-Host "8. Processando Security/DevSecOps..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "security:" + [Environment]::NewLine

$securityArquivos = @(
    "security/kubernetes/opa-policies.yaml",
    "security/terraform/devsecops.tf"
)

foreach ($arquivo in $securityArquivos) {
    $subcategoria = ""
    if ($arquivo -like "*kubernetes*") { $subcategoria = "kubernetes" }
    elseif ($arquivo -like "*terraform*") { $subcategoria = "terraform" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "security" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# 9. FINOPS
Write-Host "9. Processando FinOps..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "finops:" + [Environment]::NewLine

$finopsArquivos = @(
    "finops/budget-alerts/cloudwatch-alarms.yaml",
    "finops/cost-monitoring/kubecost-values.yaml",
    "finops/terraform/cost-optimization.tf"
)

foreach ($arquivo in $finopsArquivos) {
    $subcategoria = ""
    if ($arquivo -like "*budget-alerts*") { $subcategoria = "budget_alerts" }
    elseif ($arquivo -like "*cost-monitoring*") { $subcategoria = "cost_monitoring" }
    elseif ($arquivo -like "*terraform*") { $subcategoria = "terraform" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "finops" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# 10. TERRAFORM
Write-Host "10. Processando Terraform..." -ForegroundColor Green
$yamlContent += [Environment]::NewLine + "terraform:" + [Environment]::NewLine

# Lista de todos os arquivos Terraform
$tfArquivos = @(
    # Principal
    "terraform/providers.tf",
    
    # Modulos EKS Cluster
    "terraform/modules/eks-cluster/main.tf",
    "terraform/modules/eks-cluster/outputs.tf",
    "terraform/modules/eks-cluster/variables.tf",
    
    # Modulos EKS Node Groups
    "terraform/modules/eks-node-groups/main.tf",
    "terraform/modules/eks-node-groups/outputs.tf",
    "terraform/modules/eks-node-groups/variables.tf",
    
    # Modulos IAM
    "terraform/modules/iam/main.tf",
    "terraform/modules/iam/outputs.tf",
    "terraform/modules/iam/variables.tf",
    
    # Modulos Monitoring
    "terraform/modules/monitoring/main.tf",
    "terraform/modules/monitoring/outputs.tf",
    "terraform/modules/monitoring/variables.tf",
    
    # Modulos Networking
    "terraform/modules/networking/main.tf",
    "terraform/modules/networking/outputs.tf",
    "terraform/modules/networking/variables.tf",
    
    # Environment Dev
    "terraform/environments/dev/backend.tf",
    "terraform/environments/dev/locals.tf",
    "terraform/environments/dev/main.tf",
    "terraform/environments/dev/providers.tf",
    "terraform/environments/dev/variables.tf",
    
    # Environment Prod
    "terraform/environments/prod/backend.tf"
)

foreach ($arquivo in $tfArquivos) {
    $subcategoria = ""
    if ($arquivo -like "*modules*") {
        if ($arquivo -like "*eks-cluster*") { $subcategoria = "module_eks_cluster" }
        elseif ($arquivo -like "*eks-node-groups*") { $subcategoria = "module_eks_node_groups" }
        elseif ($arquivo -like "*iam*") { $subcategoria = "module_iam" }
        elseif ($arquivo -like "*monitoring*") { $subcategoria = "module_monitoring" }
        elseif ($arquivo -like "*networking*") { $subcategoria = "module_networking" }
        else { $subcategoria = "module" }
    }
    elseif ($arquivo -like "*environments/dev*") { $subcategoria = "environment_dev" }
    elseif ($arquivo -like "*environments/prod*") { $subcategoria = "environment_prod" }
    else { $subcategoria = "main" }
    
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "terraform" -Subcategoria $subcategoria
    if ($bloco) { $yamlContent += $bloco }
}

# Scripts Terraform
$tfScripts = @(
    "terraform/scripts/terraform-backend-init.ps1"
)

foreach ($arquivo in $tfScripts) {
    $bloco = Adicionar-Arquivo -Caminho $arquivo -Categoria "terraform" -Subcategoria "script"
    if ($bloco) { $yamlContent += $bloco }
}

# 11. RESUMO DETALHADO
Write-Host "11. Gerando resumo..." -ForegroundColor Green

$yamlContent += [Environment]::NewLine + "# ===================================================" + [Environment]::NewLine
$yamlContent += "# RESUMO DA EXPORTACAO" + [Environment]::NewLine
$yamlContent += "# ===================================================" + [Environment]::NewLine + [Environment]::NewLine

# Contar arquivos por categoria
$totalArquivos = $arquivosProcessados
$totalRaiz = ($arquivosRaiz | Where-Object { Test-Path $_ }).Count
$totalK8s = ($k8sArquivos | Where-Object { Test-Path $_ }).Count
$totalTerraform = ($tfArquivos | Where-Object { Test-Path $_ }).Count + ($tfScripts | Where-Object { Test-Path $_ }).Count
$totalSecurity = ($securityArquivos | Where-Object { Test-Path $_ }).Count
$totalFinops = ($finopsArquivos | Where-Object { Test-Path $_ }).Count
$totalPlatform = ($platformArquivos | Where-Object { Test-Path $_ }).Count
$totalDocs = ($docsArquivos | Where-Object { Test-Path $_ }).Count
$totalCompliance = ($complianceArquivos | Where-Object { Test-Path $_ }).Count
$totalScripts = ($scriptsArquivos | Where-Object { Test-Path $_ }).Count

$yamlContent += "resumo:" + [Environment]::NewLine
$yamlContent += "  total_arquivos_processados: $totalArquivos" + [Environment]::NewLine
$yamlContent += "  distribuicao:" + [Environment]::NewLine
$yamlContent += "    arquivos_raiz: $totalRaiz" + [Environment]::NewLine
$yamlContent += "    github_actions: 1" + [Environment]::NewLine
$yamlContent += "    documentacao: $totalDocs" + [Environment]::NewLine
$yamlContent += "    compliance: $totalCompliance" + [Environment]::NewLine
$yamlContent += "    kubernetes_manifests: $totalK8s" + [Environment]::NewLine
$yamlContent += "    platform_idp: $totalPlatform" + [Environment]::NewLine
$yamlContent += "    scripts_automacao: $totalScripts" + [Environment]::NewLine
$yamlContent += "    security_devsecops: $totalSecurity" + [Environment]::NewLine
$yamlContent += "    finops: $totalFinops" + [Environment]::NewLine
$yamlContent += "    terraform:" + [Environment]::NewLine
$yamlContent += "      total: $totalTerraform" + [Environment]::NewLine
$yamlContent += "      modulos: 5" + [Environment]::NewLine
$yamlContent += "      environments: 2" + [Environment]::NewLine
$yamlContent += "      scripts: 1" + [Environment]::NewLine
$yamlContent += "  estrutura_completa: true" + [Environment]::NewLine
$yamlContent += "  data_geracao: '$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')'" + [Environment]::NewLine

if ($erros.Count -gt 0) {
    $yamlContent += [Environment]::NewLine + "erros_encontrados:" + [Environment]::NewLine
    foreach ($erro in $erros) {
        $yamlContent += "  - '$erro'" + [Environment]::NewLine
    }
}

$yamlContent += [Environment]::NewLine + "# ===================================================" + [Environment]::NewLine
$yamlContent += "# DIRETORIOS DA ESTRUTURA ATUALIZADA" + [Environment]::NewLine
$yamlContent += "# ===================================================" + [Environment]::NewLine
$yamlContent += "# " + [Environment]::NewLine
$yamlContent += "# 1. compliance/              # Governanca e conformidade" + [Environment]::NewLine
$yamlContent += "# 2. docs/                    # Documentacao" + [Environment]::NewLine
$yamlContent += "# 3. finops/                  # Gerenciamento de custos" + [Environment]::NewLine
$yamlContent += "# 4. kubernetes/              # Manifests K8s" + [Environment]::NewLine
$yamlContent += "# 5. platform/                # IDP e workflows" + [Environment]::NewLine
$yamlContent += "# 6. scripts/                 # Scripts de automacao" + [Environment]::NewLine
$yamlContent += "# 7. security/                # DevSecOps" + [Environment]::NewLine
$yamlContent += "# 8. terraform/               # Infraestrutura como codigo" + [Environment]::NewLine
$yamlContent += "# " + [Environment]::NewLine
$yamlContent += "# ===================================================" + [Environment]::NewLine
$yamlContent += "# FIM DA EXPORTACAO" + [Environment]::NewLine
$yamlContent += "# ===================================================" + [Environment]::NewLine

# SALVAR ARQUIVO
try {
    $yamlContent | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
    
    # Estatisticas
    $fileInfo = Get-Item $OutputFile -ErrorAction SilentlyContinue
    if ($fileInfo) {
        $sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        $sizeMB = [math]::Round($fileInfo.Length / 1MB, 3)
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "EXPORTACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Arquivo gerado: $OutputFile" -ForegroundColor Yellow
        Write-Host "Tamanho: $sizeKB KB ($sizeMB MB)" -ForegroundColor Yellow
        Write-Host "Arquivos processados: $arquivosProcessados" -ForegroundColor Yellow
        
        Write-Host ""
        Write-Host "ESTRUTURA CAPTURADA:" -ForegroundColor Magenta
        Write-Host "  • compliance/       ($totalCompliance arquivos)" -ForegroundColor Gray
        Write-Host "  • docs/             ($totalDocs arquivos)" -ForegroundColor Gray
        Write-Host "  • finops/           ($totalFinops arquivos)" -ForegroundColor Gray
        Write-Host "  • kubernetes/       ($totalK8s arquivos)" -ForegroundColor Gray
        Write-Host "  • platform/         ($totalPlatform arquivos)" -ForegroundColor Gray
        Write-Host "  • security/         ($totalSecurity arquivos)" -ForegroundColor Gray
        Write-Host "  • terraform/        ($totalTerraform arquivos)" -ForegroundColor Gray
        
        if ($erros.Count -gt 0) {
            Write-Host ""
            Write-Host "Erros encontrados: $($erros.Count)" -ForegroundColor Red
            foreach ($erro in $erros) {
                Write-Host "   - $erro" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "COMANDOS PARA VISUALIZAR:" -ForegroundColor Magenta
        Write-Host "   Get-Content $OutputFile -First 100" -ForegroundColor Gray
        Write-Host "   code $OutputFile" -ForegroundColor Gray
        Write-Host "   Get-Content $OutputFile | more" -ForegroundColor Gray
        
    } else {
        Write-Host "ERRO: Arquivo nao foi criado" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERRO ao salvar arquivo: $_" -ForegroundColor Red
}
