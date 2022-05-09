data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "DeploymentName" {}

variable "lambda_info" {}
