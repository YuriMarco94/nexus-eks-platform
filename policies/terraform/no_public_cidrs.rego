package terraform.no_public_cidrs

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  after := rc.change.after
  after.cidr_blocks[_] == "0.0.0.0/0"
  after.from_port == 22
  msg := sprintf("SG Rule %s opens SSH to 0.0.0.0/0 (blocked).", [rc.name])
}
