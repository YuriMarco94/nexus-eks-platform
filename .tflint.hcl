config {
  module     = true
  force      = false
  disabled_by_default = false
}

plugin "aws" {
  enabled = true
  version = "0.24.1"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  
  format  = "snake_case"
  
  check_module {
    format = "snake_case"
  }
  
  check_resource {
    format = "snake_case"
  }
  
  check_variable {
    format = "snake_case"
  }
  
  check_output {
    format = "snake_case"
  }
  
  check_data_source {
    format = "snake_case"
  }
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
  
  style = "semver"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "Project",
    "ManagedBy",
    "Component"
  ]
}

rule "aws_s3_bucket_name" {
  enabled = true
}

rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = false
}

rule "aws_iam_policy_gov_friendly_arns" {
  enabled = false
}

rule "aws_instance_previous_type" {
  enabled = false
}

rule "aws_route_not_specified_target" {
  enabled = true
}

rule "aws_route_specified_multiple_targets" {
  enabled = true
}

rule "aws_vpc_previous_generation_instance_type" {
  enabled = false
}