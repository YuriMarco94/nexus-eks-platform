package terraform

# Exemplo: exige tag "Environment" em recursos com tags
deny[msg] {
  input.resource_changes[_].change.after.tags
  not input.resource_changes[_].change.after.tags.Environment
  msg := "Recurso com tags sem tag obrigatória: Environment"
}

# Exemplo: proíbe 0.0.0.0/0 em prod para regras de SG (bem básico)
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  after := rc.change.after
  after.cidr_blocks[_] == "0.0.0.0/0"
  # tenta inferir ambiente pelo nome
  contains(lower(after.description), "dev") == false
  msg := "SecurityGroupRule com 0.0.0.0/0 (revise, principalmente fora de dev)"
}
