data "aws_ami" "debian"{
    most_recent = true

    filter {
        name = "name"
        values = ["debian-13-amd64-*"]
    }

    owners = ["136693071363"]

}