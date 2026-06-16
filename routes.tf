# Route par défaut du subnet private, rediriger vers la nat_gateway
resource "aws_route_table" "private_subnet" {

    vpc_id = aws_vpc.medishare_vpc.id

    route {

        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
        Name = "Route par défaut subnet private"
    }

}

# Route par défaut du subnet public, rediriger vers l'internet gateway

resource "aws_route_table" "public_subnet" {

    vpc_id = aws_vpc.medishare_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }

    tags = {
        Name = "Route par défaut Nat Gateway"
    }

}

# associations des routes et des subnets

resource "aws_route_table_association" "public_subnet2"{
    subnet_id = aws_subnet.public_subnet2.id
    route_table_id = aws_route_table.public_subnet.id
}

resource "aws_route_table_association" "private_subnet" {
    subnet_id = aws_subnet.private_subnet.id 
    route_table_id = aws_route_table.private_subnet.id
}

resource "aws_route_table_association" "public_subnet" {
    subnet_id = aws_subnet.public_subnet.id 
    route_table_id = aws_route_table.public_subnet.id
}

resource "aws_route_table_association" "private_subnet2" {
    subnet_id      = aws_subnet.private_subnet2.id 
    route_table_id = aws_route_table.private_subnet.id
}