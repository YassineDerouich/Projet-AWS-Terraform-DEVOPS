
resource "aws_ebs_encryption_by_default" "ebs_encryption" {
  enabled = true
}


resource "aws_s3_bucket_versioning" "data_versioning" {
  bucket = aws_s3_bucket.medishare_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_inventory" "data_inventory" {
  bucket = aws_s3_bucket.medishare_data.id
  name   = "medishare-daily-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.audit_logs.arn
      prefix     = "s3-inventory"
    }
  }
}


resource "aws_wafv2_web_acl" "medishare_waf" {
  name        = "medishare-waf"
  # ✅ CORRECTION : Plus d'apostrophes pour respecter l'expression régulière d'AWS
  description = "Pare-feu de securite pour le Load Balancer" 
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-ManagedRulesCommon"
    priority = 1
    
    # ✅ CORRECTION : Syntaxe sur plusieurs lignes
    override_action { 
      none {} 
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFCommonRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MediShareWAFMetric"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "waf_alb" {
  resource_arn = aws_lb.alb.arn # Utilisé ton nom exact : aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.medishare_waf.arn
}


resource "aws_iam_role" "aws_config_role" {
  name = "aws-config-role-medishare"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "config.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "medishare-config-recorder"
  role_arn = aws_iam_role.aws_config_role.arn
}

resource "aws_config_delivery_channel" "main" {
  name           = "medishare-config-delivery"
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  depends_on     = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.audit_bucket_policy 
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_config_rule" "ebs_encryption_check" {
  name = "ebs-optimized-instances-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  depends_on = [aws_config_configuration_recorder.main]
}