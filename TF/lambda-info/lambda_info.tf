
variable "DeploymentName" {}


data "aws_lambda_function" "lambda-info" {
  function_name = join("", [var.DeploymentName, "-Lambda"])
}

output "lambda_info" {
  value = data.aws_lambda_function.lambda-info
}
