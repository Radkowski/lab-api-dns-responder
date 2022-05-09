data "aws_caller_identity" "current" {}

data "aws_region" "current" {}



# main module

variable "DeploymentRegion" {
  default = "eu-central-1"
  type    = string
}

variable "DeploymentName" {
  default = "DNS-Responder"
  type    = string
}
