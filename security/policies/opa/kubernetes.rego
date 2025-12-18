package kubernetes

deny[msg] {
  obj := input[_]
  obj.kind == "Deployment"
  c := obj.spec.template.spec.containers[_]
  not c.resources.limits
  msg := sprintf("Deployment %s sem resources.limits", [obj.metadata.name])
}

deny[msg] {
  obj := input[_]
  obj.kind == "Service"
  obj.spec.type == "LoadBalancer"
  # Se quiser permitir só no namespace gateway, ajuste aqui
  msg := sprintf("Service %s é LoadBalancer (valide se é esperado)", [obj.metadata.name])
}
