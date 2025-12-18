# (Opcional) EKS Add-on CloudWatch Observability (pra ver bonito na AWS Console)
# Nome do add-on é amazon-cloudwatch-observability nas docs da AWS. :contentReference[oaicite:1]{index=1}
resource "aws_eks_addon" "cloudwatch_observability" {
  count                       = var.enable_cloudwatch_observability_addon ? 1 : 0
  cluster_name                = data.terraform_remote_state.infra.outputs.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Namespace do Dashboard
resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

# Kubernetes Dashboard via Helm chart oficial (repo do projeto)
# Values oficiais existem no repo do dashboard (chart). :contentReference[oaicite:2]{index=2}
resource "helm_release" "kubernetes_dashboard" {
  name             = "kubernetes-dashboard"
  namespace        = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  create_namespace = false

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  version    = var.kubernetes_dashboard_chart_version

  values = [yamlencode({
    metricsScraper = { enabled = true }
  })]
}

# Admin SA (para demo/entrevista — em produção use RBAC mínimo)
resource "kubernetes_manifest" "dashboard_admin_sa" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "admin-user"
      namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    }
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

resource "kubernetes_manifest" "dashboard_admin_crb" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "dashboard-admin-user"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "cluster-admin"
    }
    subjects = [{
      kind      = "ServiceAccount"
      name      = "admin-user"
      namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    }]
  }

  depends_on = [kubernetes_manifest.dashboard_admin_sa]
}

output "dashboard_token_command" {
  value = "kubectl -n kubernetes-dashboard create token admin-user"
}

output "dashboard_port_forward_hint" {
  value = "kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443"
}
