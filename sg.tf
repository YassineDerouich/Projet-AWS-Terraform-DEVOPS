
# SECURITY GROUP FRONTEND

resource "aws_security_group" "sg_frontend"{
    name = "sg_frontend"
    description = "Allow traffic sg_frontend inbound/outbound"
    vpc_id = aws_vpc.medishare_vpc.id

    tags = { Name = "sg_frontend" }
} 

resource "aws_vpc_security_group_ingress_rule" "sg_frontend-ingress_http" {
  security_group_id = aws_security_group.sg_frontend.id
  referenced_security_group_id = aws_security_group.sg_alb.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "sg_frontend-egress_all" {
  security_group_id = aws_security_group.sg_frontend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # tous les protocoles
}

# SECURITY GROUP BACKEND

resource "aws_security_group" "sg_backend"{
    name = "sg_backend"
    description = "Allow traffic sg_backend inbound/outbound"
    vpc_id = aws_vpc.medishare_vpc.id

    tags = { Name = "sg_backend" }
} 

resource "aws_vpc_security_group_ingress_rule" "sg_backend-ingress_nodejs" {
  security_group_id = aws_security_group.sg_backend.id
  referenced_security_group_id = aws_security_group.sg_alb.id
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}



resource "aws_vpc_security_group_egress_rule" "sg_backend-egress_all" {
  security_group_id = aws_security_group.sg_backend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}


# SECURITY GROUP LOAD BALANCER (ALB)

resource "aws_security_group" "sg_alb"{
    name = "sg_alb"
    description = "Allow traffic sg-sg_alb inbound/outbound"
    vpc_id = aws_vpc.medishare_vpc.id

    tags = { Name = "sg_alb" }
} 

resource "aws_vpc_security_group_ingress_rule" "sg_alb-inbound" {
  security_group_id = aws_security_group.sg_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Règle de sortie vers le Frontend
resource "aws_vpc_security_group_egress_rule" "sg_alb-outbound_frontend" {
  security_group_id            = aws_security_group.sg_alb.id
  referenced_security_group_id = aws_security_group.sg_frontend.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# Règle de sortie vers le Backend
resource "aws_vpc_security_group_egress_rule" "sg_alb-outbound_backend" {
  security_group_id            = aws_security_group.sg_alb.id
  referenced_security_group_id = aws_security_group.sg_backend.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
}