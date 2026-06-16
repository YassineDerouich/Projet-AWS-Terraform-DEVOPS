# Génération d'un mot de passe aléatoire robuste 
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Ajout d'un petit suffixe aléatoire pour éviter les conflits de nommage dans Secrets Manager
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Stockage sécurisé du mot de passe dans AWS Secrets Manager 
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "medishare-db-credentials-${random_string.suffix.result}"
  recovery_window_in_days = 0 # Permet de détruire le secret immédiatement avec terraform destroy
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "medishare_admin"
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.medishare_db.address
  })
}

# Le Subnet Group indique dans quels sous-réseaux privés placer la BDD
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "medishare-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id,aws_subnet.private_subnet2.id]
  
  tags = { Name = "Medishare DB Subnet Group" }
}

#  Le Security Group  de la RDS : Zero Trust, donc pas d'egress
resource "aws_security_group" "sg_rds" {
  name        = "sg_rds"
  description = "Autorise le trafic SQL depuis le backend uniquement"
  vpc_id      = aws_vpc.medishare_vpc.id

  tags = { Name = "sg_rds" }
}

resource "aws_vpc_security_group_ingress_rule" "sg_rds-ingress" {
  security_group_id            = aws_security_group.sg_rds.id
  referenced_security_group_id = aws_security_group.sg_backend.id # N'écoute QUE le backend !
  from_port                    = 5432 # Port par défaut de PostgreSQL
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

#  La Base de Données PostgreSQL , 10go
resource "aws_db_instance" "medishare_db" {
  identifier             = "medishare-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  storage_type           = "gp2"
  
  db_name                = "medisharedb"
  username               = "medishare_admin"
  password               = random_password.db_password.result
  
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  
  storage_encrypted      = true # OBLIGATOIRE POUR LA PHASE 3 (Chiffrement)
  skip_final_snapshot    = true # Indispensable pour que 'terraform destroy' ne bloque pas à la fin du projet
  publicly_accessible    = false

  tags = { Name = "Medishare RDS" }
}