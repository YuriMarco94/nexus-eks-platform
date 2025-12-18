param(
  [string]$ClusterName = "Nexus-dev",
  [string]$Region = "us-east-1",
  [string]$Profile = "eks-dev"
)

aws eks update-kubeconfig --name $ClusterName --region $Region --profile $Profile

# 1) Gateway API CRDs (kustomize remoto)
kubectl apply -k kubernetes/manifests/gateway-api

# 2) Metrics Server (necessário pro Dashboard mostrar CPU/Mem)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3) NGINX Gateway Fabric via Helm (OCI chart)
helm upgrade --install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric `
  --version 2.2.2 `
  -n nginx-gateway --create-namespace `
  -f kubernetes/manifests/nginx-gateway-fabric/values.yaml

kubectl wait --timeout=5m -n nginx-gateway deploy/ngf-nginx-gateway-fabric --for=condition=Available

# 4) Dashboard (via Helm)
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard `
  -n kubernetes-dashboard --create-namespace `
  -f kubernetes/manifests/dashboard/kubernetes-dashboard-values.yaml

# 5) Namespaces + demo + routes (dev/prod)
kubectl apply -k kubernetes/overlays/dev
kubectl apply -k kubernetes/overlays/prod
