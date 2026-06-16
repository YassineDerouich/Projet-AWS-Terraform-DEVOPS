# la mémoire de l'infra terraform est stocké sur s3
terraform {
  backend "s3" {
    bucket = "my-terraform-cloud-native"
    key    = "terraform/state.tfstate"
    region = "eu-west-1"
    use_lockfile = true
  }
}