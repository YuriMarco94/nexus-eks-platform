# =========================================
# BOOTSTRAP PLATFORM - PART B (AWS)
# - GitHub OIDC Provider
# - IAM Role (GitHub Actions assume role)
# - EKS Access Entry + Cluster Admin Policy
# =========================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ====== AJUSTE AQUI SE PRECISAR ======
$RepoRoot  = "C:\Users\Yuri\nexus-eks-platform"
$AwsRegion = "us-east-1"

# Nome da Role que o GitHub Actions vai assumir
$RoleName  = "GitHubActions-EKS-Deploy"

# Clusters (se prod não existir ainda, ele ignora)
$ClusterDev  = "Nexus-dev"
$ClusterProd = "Nexus-prod"

# Se quiser forçar (senão detecta pelo git remote):
$RepoFullNameOverride = ""   # ex: "YuriMarco94/nexus-eks-platform"

# =========================================
function Exec-Cmd([string]$cmd, [bool]$silent = $false) {
  if (-not $silent) { Write-Host ">> $cmd" -ForegroundColor DarkGray }
  $out = & cmd.exe /c $cmd 2>&1
  return ($out | Out-String).TrimEnd()
}

function Aws-Json([string]$awsArgs) {
  $cmd = "aws $awsArgs --output json"
  $out = Exec-Cmd $cmd $true
  if ($LASTEXITCODE -ne 0) { throw $out }
  return ($out | ConvertFrom-Json)
}

function Aws-Text([string]$awsArgs) {
  $cmd = "aws $awsArgs --output text"
  $out = Exec-Cmd $cmd $true
  if ($LASTEXITCODE -ne 0) { throw $out }
  return $out.Trim()
}

function TryAws-Json([string]$awsArgs) {
  try { return Aws-Json $awsArgs } catch { return $null }
}

function Get-RepoFullName {
  if ($RepoFullNameOverride -and $RepoFullNameOverride.Trim().Length -gt 0) {
    return $RepoFullNameOverride.Trim()
  }

  $remote = Exec-Cmd "git -C ""$RepoRoot"" config --get remote.origin.url" $true
  if (-not $remote) { throw "Não consegui ler o remote.origin.url. Preencha RepoFullNameOverride." }

  # https://github.com/OWNER/REPO.git  ou  git@github.com:OWNER/REPO.git
  if ($remote -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(\.git)?$') {
    return "$($Matches.owner)/$($Matches.repo)"
  }

  throw "Remote origin não parece GitHub: $remote. Preencha RepoFullNameOverride."
}

function Ensure-OidcProvider {
  Write-Host "`n== OIDC Provider ==" -ForegroundColor Cyan

  $providers = TryAws-Json "iam list-open-id-connect-providers"
  if (-not $providers) { throw "Falha ao listar OIDC providers." }

  foreach ($p in $providers.OpenIDConnectProviderList) {
    $arn = $p.Arn
    $info = TryAws-Json "iam get-open-id-connect-provider --open-id-connect-provider-arn $arn"
    if ($info -and $info.Url -eq "token.actions.githubusercontent.com") {
      Write-Host "OIDC provider já existe: $arn" -ForegroundColor Green
      return $arn
    }
  }

  # Se não existe, cria
  # Thumbprint padrão usado em vários exemplos; se teu ambiente exigir outro, a AWS retorna erro aqui.
  $thumb = "6938fd4d98bab03faadb97b34396831e3780aea1"
  $created = Aws-Json "iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list $thumb"
  Write-Host "OIDC provider criado: $($created.OpenIDConnectProviderArn)" -ForegroundColor Green
  return $created.OpenIDConnectProviderArn
}

function Ensure-Role([string]$oidcArn, [string]$repoFullName) {
  Write-Host "`n== IAM Role ==" -ForegroundColor Cyan

  $trust = @{
    Version   = "2012-10-17"
    Statement = @(
      @{
        Effect    = "Allow"
        Principal = @{ Federated = $oidcArn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = @{
          StringEquals = @{
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = @{
            "token.actions.githubusercontent.com:sub" = @(
              "repo:$repoFullName:ref:refs/heads/develop",
              "repo:$repoFullName:ref:refs/heads/master",
              "repo:$repoFullName:pull_request"
            )
          }
        }
      }
    )
  } | ConvertTo-Json -Depth 30

  $tmpTrust = Join-Path $env:TEMP "gh-oidc-trust-$RoleName.json"
  Set-Content -Encoding utf8 -Path $tmpTrust -Value $trust

  $existing = TryAws-Json "iam get-role --role-name $RoleName"
  if (-not $existing) {
    $fileDoc = "file://""$tmpTrust"""
    $created = Aws-Json "iam create-role --role-name $RoleName --assume-role-policy-document $fileDoc"
    Write-Host "Role criada: $($created.Role.Arn)" -ForegroundColor Green
    return $created.Role.Arn
  }

  # Atualiza trust policy
  $fileDoc = "file://""$tmpTrust"""
  Exec-Cmd "aws iam update-assume-role-policy --role-name $RoleName --policy-document $fileDoc" $true | Out-Null
  $roleArn = $existing.Role.Arn
  Write-Host "Role já existia. Trust policy atualizada: $roleArn" -ForegroundColor Green
  return $roleArn
}

function Ensure-InlinePolicy([string]$roleName) {
  Write-Host "`n== Attach inline policy (eks:DescribeCluster) ==" -ForegroundColor Cyan

  $pol = @{
    Version   = "2012-10-17"
    Statement = @(
      @{
        Effect   = "Allow"
        Action   = @("eks:DescribeCluster")
        Resource = "*"
      }
    )
  } | ConvertTo-Json -Depth 10

  $tmpPol = Join-Path $env:TEMP "gh-oidc-inline-$roleName.json"
  Set-Content -Encoding utf8 -Path $tmpPol -Value $pol

  $filePol = "file://""$tmpPol"""
  Exec-Cmd "aws iam put-role-policy --role-name $roleName --policy-name EKSDescribeCluster --policy-document $filePol" $true | Out-Null
  Write-Host "Inline policy ensured." -ForegroundColor Green
}

function Ensure-EksAccess([string]$clusterName, [string]$principalArn, [string]$region) {
  Write-Host "`n== EKS Access Entry: $clusterName ==" -ForegroundColor Cyan

  $cluster = TryAws-Json "eks describe-cluster --name $clusterName --region $region"
  if (-not $cluster) {
    Write-Host "Cluster não existe (skip): $clusterName" -ForegroundColor Yellow
    return
  }

  $ae = TryAws-Json "eks describe-access-entry --cluster-name $clusterName --principal-arn $principalArn --region $region"
  if (-not $ae) {
    Exec-Cmd "aws eks create-access-entry --cluster-name $clusterName --principal-arn $principalArn --region $region" $true | Out-Null
    Write-Host "Access entry criado." -ForegroundColor Green
  } else {
    Write-Host "Access entry já existe." -ForegroundColor DarkGray
  }

  $assocList = TryAws-Json "eks list-associated-access-policies --cluster-name $clusterName --principal-arn $principalArn --region $region"
  $already = $false
  if ($assocList -and $assocList.associatedAccessPolicies) {
    foreach ($a in $assocList.associatedAccessPolicies) {
      if ($a.policyArn -like "*AmazonEKSClusterAdminPolicy*") { $already = $true }
    }
  }

  if (-not $already) {
    Exec-Cmd "aws eks associate-access-policy --cluster-name $clusterName --principal-arn $principalArn --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region $region" $true | Out-Null
    Write-Host "Associated AmazonEKSClusterAdminPolicy." -ForegroundColor Green
  } else {
    Write-Host "ClusterAdminPolicy já estava associada." -ForegroundColor DarkGray
  }
}

# =========================================
Set-Location $RepoRoot

Write-Host "== AWS identity ==" -ForegroundColor Cyan
$id = Aws-Json "sts get-caller-identity"
Write-Host "AccountId: $($id.Account)" -ForegroundColor Green
Write-Host "CallerArn: $($id.Arn)" -ForegroundColor DarkGray

$repoFullName = Get-RepoFullName
Write-Host "`n== GitHub repo detected ==" -ForegroundColor Cyan
Write-Host "Repo: $repoFullName" -ForegroundColor Green

$oidcArn = Ensure-OidcProvider
$roleArn = Ensure-Role $oidcArn $repoFullName
Ensure-InlinePolicy $RoleName

Ensure-EksAccess $ClusterDev  $roleArn $AwsRegion
Ensure-EksAccess $ClusterProd $roleArn $AwsRegion

Write-Host "`n✅ PART B OK" -ForegroundColor Cyan
Write-Host "Role ARN (use in GitHub Variables):" -ForegroundColor Cyan
Write-Host $roleArn -ForegroundColor Green

Write-Host "`nNext: set GitHub Secrets:" -ForegroundColor Cyan
Write-Host " - GRAFANA_ADMIN_USER" -ForegroundColor Cyan
Write-Host " - GRAFANA_ADMIN_PASSWORD" -ForegroundColor Cyan
