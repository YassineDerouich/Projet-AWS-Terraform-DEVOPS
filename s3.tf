# 1. Création d'un nom de bucket unique
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}


# Gestion de la clé KMS 


resource "aws_kms_key" "medishare_kms_key" {
  description             = "Clé KMS pour chiffrer les données patients MediShare"
  deletion_window_in_days = 7    # Permet de détruire la clé rapidement si besoin
  enable_key_rotation     = true # rotation  automatique
  
  tags = { Name = "medishare-kms-key" }
}

# Un alias pour retrouver la clé facilement dans la console AWS
resource "aws_kms_alias" "medishare_kms_alias" {
  name          = "alias/medishare-s3-key"
  target_key_id = aws_kms_key.medishare_kms_key.key_id
}


#  GESTION DU STOCKAGE S3


resource "aws_s3_bucket" "medishare_data" {
  bucket        = "medishare-patient-data-${random_string.bucket_suffix.result}"
  force_destroy = true 
}

# Chiffrement obligatoire avec NOTRE clé KMS + Optimisation des coûts
resource "aws_s3_bucket_server_side_encryption_configuration" "medishare_crypto" {
  bucket = aws_s3_bucket.medishare_data.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.medishare_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    # LE SECRET ÉCONOMIQUE EST ICI 👇
    bucket_key_enabled = true 
  }
}

resource "aws_s3_bucket_cors_configuration" "medishare_cors" {
  bucket = aws_s3_bucket.medishare_data.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] 
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# PERMISSIONS IAM POUR LE BACKEND


resource "aws_iam_role_policy" "backend_app_policy" {
  name   = "backend-app-policy-with-kms"
  

  role   = aws_iam_role.ssm_ec2_role.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Droit de lire le mot de passe BDD
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db_secret.arn # Assure-toi que cette ressource existe bien dans un de tes fichiers .tf
      },
      {
        # Droit d'écrire, de lire et de lister dans S3
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.medishare_data.arn,
          "${aws_s3_bucket.medishare_data.arn}/*"
        ]
      },
      {
        # Droit d'utiliser la clé KMS pour chiffrer/déchiffrer
        Effect   = "Allow"
        Action   = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.medishare_kms_key.arn
      }
    ]
  })
}

output "s3_bucket_name" {
  value = aws_s3_bucket.medishare_data.bucket
}