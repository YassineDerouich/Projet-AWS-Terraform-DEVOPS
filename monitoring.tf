# Bucket d'Audit 
resource "aws_s3_bucket" "audit_logs" {
  bucket        = "medishare-audit-${random_string.bucket_suffix.result}"
  force_destroy = true
}

#  Politique du Bucket pour autoriser CloudTrail ET AWS Config
resource "aws_s3_bucket_policy" "audit_bucket_policy" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #  Permissions pour CloudTrail 
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/AWSLogs/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
      #  Permissions pour AWS Config
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

# Règle de cycle de vie : On supprime les vieux logs après 3 jours automatiquement
resource "aws_s3_bucket_lifecycle_configuration" "audit_lifecycle" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    id     = "auto-delete-logs"
    status = "Enabled"
    expiration {
      days = 3
    }
  }
}

#  CloudTrail 
resource "aws_cloudtrail" "main_trail" {
  name                          = "medishare-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = false
  enable_logging                = true

  # On attend que la nouvelle politique combinée soit bien appliquée
  depends_on = [aws_s3_bucket_policy.audit_bucket_policy]
}

# CloudWatch Log Group (Rétention courte)
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/aws/ec2/medishare-backend"
  retention_in_days = 3 # On ne garde que 3 jours de logs applicatifs
}

#  SNS Topic pour les alertes (par mail)
resource "aws_sns_topic" "security_alerts" {
  name = "medishare-security-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "@" # 

# Alarme de Brute Force 
resource "aws_cloudwatch_log_metric_filter" "auth_failure" {
  name           = "AuthFailureCount"
  pattern        = "401" # On surveille les erreurs "401 Unauthorized"
  log_group_name = aws_cloudwatch_log_group.backend_logs.name

  metric_transformation {
    name      = "AuthFailures"
    namespace = "MediShare/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "alert_brute_force" {
  alarm_name          = "Alerte-BruteForce-Detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AuthFailures"
  namespace           = "MediShare/Security"
  period              = "300" # Fenêtre de 5 minutes
  statistic           = "Sum"
  threshold           = "3"   # Alerte si 3 échecs en 5 min
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}