#  elastic ip requise pour la nat gateway
resource "aws_eip" "nat_gateway_eip"{
    domain = "vpc"

    tags = {
        Name = "Nat Gateway Eip"
    }
}

resource "aws_nat_gateway" "nat_gateway"{

    allocation_id = aws_eip.nat_gateway_eip.id
    subnet_id = aws_subnet.public_subnet.id

    depends_on = [aws_internet_gateway.internet_gateway]

    tags = {
        Name = "Nat Gateway"
    }

}