package terraform.require_tags

deny[msg] {
  input.resource_changes[_].type == "aws_*"
  change := input.resource_changes[_]
  after := change.change.after
  not after.tags
  msg := sprintf("Resource %s (%s) must have tags.", [change.name, change.type])
}
