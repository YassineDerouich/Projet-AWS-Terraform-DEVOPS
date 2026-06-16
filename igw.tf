resource "aws_internet_gateway" "internet_gateway" {

    vpc_id = aws_vpc.medishare_vpc.id

    tags = {
        Name = " Internet Gateway"
    }
}