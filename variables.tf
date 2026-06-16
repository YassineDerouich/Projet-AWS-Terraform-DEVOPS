variable "aws_region" {
    description = "région de déploiement"
    type = string
}

variable "vpc_cidr" {
    description = "bloc cidr du vpc"
    type = string
}

variable "public_subnet_cidr"{
    description = "CIDR pour le subnet public"
    type = string
}

variable "public_subnet2_cidr"{
    description = "CIDR pour le subnet public2"
    type = string
}

variable "private_subnet_cidr" {
    description = "CIDR pour le subnet privé"
    type = string
}

variable "private_subnet2_cidr" {
    description = "CIDR pour le subnet privé2"
    type = string
}