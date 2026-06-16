
resource "aws_codecommit_repository" "medishare_repo" {
  repository_name = "medishare-backend"
  description     = "Dépôt sécurisé pour le code source du backend MediShare"
}


resource "aws_iam_role" "codebuild_role" {
  name = "medishare-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { 
        Effect = "Allow", 
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], 
        Resource = "*" 
      },
      { 
        Effect = "Allow", 
        Action = ["codecommit:GitPull"], 
        Resource = aws_codecommit_repository.medishare_repo.arn 
      }
    ]
  })
}


resource "aws_codebuild_project" "medishare_security_scan" {
  name          = "medishare-security-sast"
  description   = "Scan DevSecOps pour détecter les vulnérabilités NPM"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.medishare_repo.clone_url_http
    
    buildspec = <<EOF
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  pre_build:
    commands:
      - echo "Démarrage de l'analyse DevSecOps"
      - npm install
  build:
    commands:
      - echo "Scan des vulnérabilités avec npm audit..."
      # La commande échouera et bloquera la pipeline si une faille 'high' est trouvée
      - npm audit --audit-level=high 
      - echo "✅ Scan terminé avec succès. Aucune vulnérabilité critique."
EOF
  }
}