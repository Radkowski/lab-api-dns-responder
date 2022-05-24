data "aws_caller_identity" "current" {}

data "aws_region" "current" {}





variable "DeploymentRegion" {
  default = "eu-central-1"
  type    = string
}

variable "DeploymentName" {
  default = "API-DNS-Responder-v2"
  type    = string
}

variable "VPCID" {
  default = "vpc-changeme"
  type    = string
}

variable "SubnetsID" {
  default = ["subnet-changeme", "subnet-changeme"]
  type    = list(string)
}


variable "CERTARN" {
  default = "arn:aws:acm:eu-central-1:changeme"
  type    = string
}

variable "SSL-ENABLE" {
  default = false
  type    = bool
}
