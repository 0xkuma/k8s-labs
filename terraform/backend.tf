terraform {
  backend "s3" {
    bucket = "eddie-terraform"
    key    = "k8s-labs/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
