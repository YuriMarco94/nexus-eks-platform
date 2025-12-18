# DevSecOps Security Module
module "devsecops" {
  source = "./modules/devsecops"

  environment  = var.environment
  cluster_name = local.cluster_name
  region       = var.aws_region

  # Security scanning
  enable_image_scanning    = true
  enable_container_runtime = true
  enable_network_policies  = true
  enable_secrets_scanning  = true

  # Compliance frameworks
  compliance_frameworks = [
    "CIS-EKS-1.2",
    "NIST-800-53",
    "PCI-DSS-4.0",
    "GDPR"
  ]
}

# Security Hub integration
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.main]
}

# ECR with image scanning
resource "aws_ecr_repository" "secured" {
  name                 = "nexus-${var.environment}-secured"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = merge(var.global_tags, {
    SecurityLevel = "high"
    DataEncrypted = "true"
  })
}

resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR encryption"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService"    = "ecr.${var.aws_region}.amazonaws.com"
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# GuardDuty for threat detection
resource "aws_guardduty_detector" "eks" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

resource "aws_guardduty_filter" "critical_findings" {
  name        = "CriticalEKSFindings"
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.eks.id
  rank        = 1

  finding_criteria {
    criterion {
      field  = "severity"
      equals = ["7", "8"] # Critical and High
    }
    criterion {
      field  = "resourceType"
      equals = ["EKSCluster"]
    }
  }
}