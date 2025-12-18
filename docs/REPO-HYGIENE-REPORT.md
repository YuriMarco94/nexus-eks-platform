# Repo Hygiene Report

Generated: 2025-12-17 23:52:34

## Critical findings

- **Terraform .terraform directories found**: 3 (should NOT be committed)
- **Terraform state files found**: 2 (must NOT be committed)
- **Backup (*.bak) files found**: 7 (remove/ignore)

## Forbidden folders

- C:\Users\Yuri\nexus-eks-platform\terraform\.terraform
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev-addons\.terraform
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev\.terraform

## Forbidden files (by pattern)

- C:\Users\Yuri\nexus-eks-platform\.github\workflows\deploy-k8s-dev.yml.20251217-225737.bak
- C:\Users\Yuri\nexus-eks-platform\.github\workflows\deploy-k8s-prod.yml.20251217-225737.bak
- C:\Users\Yuri\nexus-eks-platform\.github\workflows\main-pipeline.yml.bak
- C:\Users\Yuri\nexus-eks-platform\.github\workflows\terraform-apply-dev.yml.20251217-225737.bak
- C:\Users\Yuri\nexus-eks-platform\.github\workflows\terraform-plan.yml.20251217-225737.bak
- C:\Users\Yuri\nexus-eks-platform\kubernetes\manifests\monitoring\kube-prometheus-stack-values.yaml.20251217-222140.bak
- C:\Users\Yuri\nexus-eks-platform\kubernetes\manifests\monitoring\kube-prometheus-stack-values.yaml.20251217-225737.bak
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev-addons\.terraform\terraform.tfstate
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev-addons\terraform.tfvars
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev\.terraform\terraform.tfstate
- C:\Users\Yuri\nexus-eks-platform\terraform\environments\dev\terraform.tfvars

## Duplicate filenames (count > 3)

- **LICENSE.txt** x8
- **main.tf** x8
- **variables.tf** x8
- **outputs.tf** x7
- **kustomization.yaml** x6
- **namespace.yaml** x6
- **gateway.yaml** x5

## Kubernetes structure

- kubernetes/base: True
- kubernetes/overlays: True
- kubernetes/manifests: True

## Recommendations (based on your current tree)

- Remove/ignore: **terraform/**/.terraform/**, **terraform/**/.terraform.lock.hcl is OK**, but **.terraform/** is NOT.
- Remove/ignore: **terraform/**/terraform.tfstate*** and any *.tfstate*.
- Remove/ignore: **.github/workflows/*.bak**, **kube-prometheus-stack-values.yaml.*.bak**, any *.bak.
- Prefer single k8s source of truth: **kubernetes/base + kubernetes/overlays + kubernetes/manifests**.
- If unused, remove legacy folders: **kubernetes/demo**, **kubernetes/gateway**.
- Avoid committing real 	erraform.tfvars. Commit 	erraform.tfvars.example and ignore 	erraform.tfvars.

