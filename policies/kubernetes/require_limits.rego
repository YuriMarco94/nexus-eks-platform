package kubernetes.require_limits

deny[msg] {
  kind := input.kind
  kind == "Deployment"
  c := input.spec.template.spec.containers[_]
  not c.resources.limits
  msg := sprintf("Deployment %s: container %s must define resources.limits", [input.metadata.name, c.name])
}
