<#
repo-audit.ps1
- Audit + optional cleanup for a "senior" DevSecOps/FinOps platform repo
- Default: only reports
- Use -Apply to actually fix/remove things
#>

[CmdletBinding()]
param(
  [switch]$Apply,
  [switch]$CreateStubs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

function Ensure-Dir($p){
  if(!(Test-Path $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Is-GitRepo {
  return (Test-Path ".git")
}

function Git-Tracked($path){
  if(!(Is-GitRepo)){ return $false }
  $p = $path.Replace('\','/')
  $out = & git ls-files --error-unmatch $p 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Safe-Remove($path){
  if(Test-Path $path){
    Remove-Item -Recurse -Force $path
  }
}

function Git-RemoveIfTracked($path){
  if(!(Is-GitRepo)){ return }
  if(Git-Tracked $path){
    & git rm -r --force -- $path | Out-Null
  }
}

function Upsert-GitIgnore($lines){
  $gi = ".gitignore"
  $existing = @()
  if(Test-Path $gi){ $existing = Get-Content $gi }
  $toAdd = @()
  foreach($l in $lines){
    if(-not ($existing -contains $l)){ $toAdd += $l }
  }
  if($toAdd.Count -gt 0){
    Add-Content -Path $gi -Value ($toAdd -join "`r`n")
    Write-Ok "Updated .gitignore (+$($toAdd.Count) lines)"
  } else {
    Write-Info ".gitignore already contains required rules"
  }
}

# -------------------------
# Repo root
# -------------------------
$RepoRoot = (Get-Location).Path
Write-Info "RepoRoot: $RepoRoot"
if(!(Is-GitRepo)){
  Write-Warn "Not a git repo (no .git). Some checks will be limited."
}

Ensure-Dir "docs"

# -------------------------
# Rules / patterns
# -------------------------
$ForbiddenFolders = @(
  ".terraform",
  "node_modules",
  ".venv",
  "venv",
  ".pytest_cache",
  ".cache"
)

$ForbiddenFilePatterns = @(
  "*.tfstate",
  "*.tfstate.*",
  "*.tfvars",
  "*.bak",
  "*.log",
  "*.tmp",
  "*~"
)

# What we expect in a clean platform repo
$RecommendedFiles = @(
  "SECURITY.md",
  "CONTRIBUTING.md",
  ".editorconfig",
  ".gitattributes"
)

# -------------------------
# Scan
# -------------------------
Write-Info "Scanning filesystem..."
$all = Get-ChildItem -Recurse -Force -File | Where-Object {
  $_.FullName -notmatch "\\.git\\"
}

# 1) Forbidden files
$hitsForbiddenFiles = @()
foreach($pat in $ForbiddenFilePatterns){
  $hitsForbiddenFiles += $all | Where-Object { $_.Name -like $pat }
}

# 2) Forbidden folders (any depth)
$hitsForbiddenFolders = @()
foreach($f in $ForbiddenFolders){
  $hitsForbiddenFolders += Get-ChildItem -Recurse -Force -Directory -Filter $f -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "\\.git\\" }
}

# 3) Special: terraform state & .terraform directories are critical
$hitsTerraformState = $all | Where-Object { $_.Name -like "*.tfstate*" -or $_.FullName -match "\\.terraform\\" }
$hitsTerraformCache = Get-ChildItem -Recurse -Force -Directory -Filter ".terraform" -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch "\\.git\\" }

# 4) Duplicates by file name (helps catch manifest mess)
$dups = $all | Group-Object Name | Where-Object { $_.Count -gt 3 } | Sort-Object Count -Descending

# 5) K8s structure sanity hints
$k8sPaths = @(
  "kubernetes/base",
  "kubernetes/overlays",
  "kubernetes/manifests"
)

$k8sExists = $k8sPaths | ForEach-Object { @{Path=$_; Exists=(Test-Path $_)} }

# -------------------------
# Report
# -------------------------
$report = @()
$report += "# Repo Hygiene Report"
$report += ""
$report += "Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
$report += ""

$report += "## Critical findings"
$report += ""
if($hitsTerraformCache.Count -gt 0){
  $report += "- **Terraform .terraform directories found**: $($hitsTerraformCache.Count) (should NOT be committed)"
} else {
  $report += "- Terraform .terraform directories: OK"
}

if(($all | Where-Object { $_.Name -like "*.tfstate*" }).Count -gt 0){
  $report += "- **Terraform state files found**: $(( $all | Where-Object { $_.Name -like "*.tfstate*" } ).Count) (must NOT be committed)"
} else {
  $report += "- Terraform state files: OK"
}

$bakCount = ($all | Where-Object { $_.Name -like "*.bak" }).Count
if($bakCount -gt 0){
  $report += "- **Backup (*.bak) files found**: $bakCount (remove/ignore)"
} else {
  $report += "- Backup (*.bak) files: OK"
}

$report += ""
$report += "## Forbidden folders"
$report += ""
if($hitsForbiddenFolders.Count -gt 0){
  $hitsForbiddenFolders | Select-Object -ExpandProperty FullName | Sort-Object | ForEach-Object { $report += "- $($_)" }
} else {
  $report += "- None"
}

$report += ""
$report += "## Forbidden files (by pattern)"
$report += ""
if($hitsForbiddenFiles.Count -gt 0){
  $hitsForbiddenFiles | Select-Object -ExpandProperty FullName | Sort-Object | ForEach-Object { $report += "- $($_)" }
} else {
  $report += "- None"
}

$report += ""
$report += "## Duplicate filenames (count > 3)"
$report += ""
if($dups.Count -gt 0){
  foreach($g in $dups){
    $report += "- **$($g.Name)** x$($g.Count)"
  }
} else {
  $report += "- None"
}

$report += ""
$report += "## Kubernetes structure"
$report += ""
foreach($k in $k8sExists){
  $report += "- $($k.Path): $($k.Exists)"
}

$report += ""
$report += "## Recommendations (based on your current tree)"
$report += ""
$report += "- Remove/ignore: **terraform/**/.terraform/**, **terraform/**/.terraform.lock.hcl is OK**, but **.terraform/** is NOT."
$report += "- Remove/ignore: **terraform/**/terraform.tfstate*** and any *.tfstate*."
$report += "- Remove/ignore: **.github/workflows/*.bak**, **kube-prometheus-stack-values.yaml.*.bak**, any *.bak."
$report += "- Prefer single k8s source of truth: **kubernetes/base + kubernetes/overlays + kubernetes/manifests**."
$report += "- If unused, remove legacy folders: **kubernetes/demo**, **kubernetes/gateway**."
$report += "- Avoid committing real `terraform.tfvars`. Commit `terraform.tfvars.example` and ignore `terraform.tfvars`."
$report += ""

$reportPath = "docs/REPO-HYGIENE-REPORT.md"
Set-Content -Encoding utf8 -Path $reportPath -Value ($report -join "`n")
Write-Ok "Report written: $reportPath"

# -------------------------
# Apply fixes (optional)
# -------------------------
if($Apply){
  Write-Warn "APPLY mode enabled: cleaning repo..."

  # Update .gitignore with senior defaults
  Upsert-GitIgnore @(
    "",
    "# --- Terraform ---",
    "**/.terraform/",
    "**/*.tfstate",
    "**/*.tfstate.*",
    "**/terraform.tfstate",
    "**/terraform.tfstate.backup",
    "**/crash.log",
    "**/crash.*.log",
    "# Keep lockfiles committed",
    "!**/.terraform.lock.hcl",
    "",
    "# Local tfvars (use *.example committed instead)",
    "**/terraform.tfvars",
    "!**/terraform.tfvars.example",
    "",
    "# --- Backups / OS junk ---",
    "*.bak",
    "*.tmp",
    "*.log",
    "*~",
    "Thumbs.db",
    ".DS_Store",
    "",
    "# --- Node/Python caches ---",
    "node_modules/",
    ".venv/",
    "venv/",
    ".pytest_cache/"
  )

  # Remove tracked forbidden folders
  foreach($d in $hitsTerraformCache){
    $rel = Resolve-Path $d.FullName | ForEach-Object { $_.Path }
    $rel = $rel.Substring($RepoRoot.Length).TrimStart('\')
    Write-Warn "Removing Terraform cache dir: $rel"
    Git-RemoveIfTracked $rel
    Safe-Remove $rel
  }

  # Remove tracked state files
  $stateFiles = $all | Where-Object { $_.Name -like "*.tfstate*" }
  foreach($f in $stateFiles){
    $rel = $f.FullName.Substring($RepoRoot.Length).TrimStart('\')
    Write-Warn "Removing TF state file: $rel"
    Git-RemoveIfTracked $rel
    Safe-Remove $rel
  }

  # Remove *.bak (only backups)
  $bakFiles = $all | Where-Object { $_.Name -like "*.bak" }
  foreach($f in $bakFiles){
    $rel = $f.FullName.Substring($RepoRoot.Length).TrimStart('\')
    Write-Warn "Removing backup file: $rel"
    Git-RemoveIfTracked $rel
    Safe-Remove $rel
  }

  # Optional: create stubs
  if($CreateStubs){
    Write-Info "Creating recommended stubs if missing..."
    if(!(Test-Path "SECURITY.md")){
@"
# Security Policy

## Reporting a Vulnerability
Please open a private security report (preferred) or contact the maintainers.
Do not open public issues for sensitive security findings.
"@ | Set-Content -Encoding utf8 -Path "SECURITY.md"
      Write-Ok "Created SECURITY.md"
    }

    if(!(Test-Path "CONTRIBUTING.md")){
@"
# Contributing

## Branching
- Work happens on `develop`
- Open PRs from `develop` -> `master`

## Quality Gates
- Terraform fmt/validate/plan
- Policy checks (OPA/Conftest)
- Security scans (tfsec/checkov/trivy/gitleaks)
"@ | Set-Content -Encoding utf8 -Path "CONTRIBUTING.md"
      Write-Ok "Created CONTRIBUTING.md"
    }

    if(!(Test-Path ".editorconfig")){
@"
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2

[*.ps1]
end_of_line = crlf
indent_size = 2
"@ | Set-Content -Encoding utf8 -Path ".editorconfig"
      Write-Ok "Created .editorconfig"
    }

    if(!(Test-Path ".gitattributes")){
@"
# Keep GitHub Actions and YAML consistent
*.yml text eol=lf
*.yaml text eol=lf

# PowerShell usually CRLF on Windows is ok
*.ps1 text eol=crlf
"@ | Set-Content -Encoding utf8 -Path ".gitattributes"
      Write-Ok "Created .gitattributes"
    }
  }

  Write-Ok "Cleanup done. Review changes with: git status"
  Write-Info "Tip: commit message suggestion: 'Repo hygiene: remove terraform cache/state + backup files'"
}

Write-Info "Done."
