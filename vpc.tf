resource "aws_vpc" "medishare_vpc" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "medishare_vpc"
    }

}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.medishare_vpc.id
    cidr_block = var.public_subnet_cidr
    availability_zone = "${var.aws_region}a"
    tags = {
        Name = "Public Subnet az-a"
    }

}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.medishare_vpc.id
    cidr_block = var.private_subnet_cidr
    availability_zone = "${var.aws_region}a"

    tags = {
        Name = "Private Subnet az-a"
    }

}

resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.medishare_vpc.id
    cidr_block = var.public_subnet2_cidr
    availability_zone = "${var.aws_region}b"

    tags = {
        Name = "Public Subnet 2 az-b"
    }

}

resource "aws_subnet" "private_subnet2" {
    vpc_id = aws_vpc.medishare_vpc.id
    cidr_block = var.private_subnet2_cidr
    availability_zone = "${var.aws_region}b"

    tags = {
        Name = "Private Subnet az-b"
    }

}
