
# RÔLE ET PROFIL D'INSTANCE DE BASE POUR LE BACKEND


resource "aws_iam_role" "ssm_ec2_role" {
  name = "ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Permet la connexion via AWS Systems Manager  sans ouvrir de port SSH
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


#  NOUVEAU : AUTORISATION POUR LE MONITORING CLOUDWATCH



resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "ec2-cloudwatch-logs-policy"
  role = aws_iam_role.ssm_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        # On autorise uniquement l'écriture dans le  groupe de logs spécifique
        Resource = "arn:aws:logs:*:*:log-group:/aws/ec2/medishare-backend:*"
      }
    ]
  })
}


# PROFIL D'INSTANCE


resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2_role.name
}