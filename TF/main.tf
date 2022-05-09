
module "DUMMY-LAMBDA" {
  source         = "./dummy-lambda"
  DeploymentName = var.DeploymentName
}

module "INFRA" {
  depends_on     = [module.DUMMY-LAMBDA]
  source         = "./infra"
  DeploymentName = var.DeploymentName
}


module "LAMBDA-INFO" {
  source         = "./lambda-info"
  depends_on     = [module.INFRA]
  DeploymentName = var.DeploymentName
}


module "API-GW" {
  source         = "./api-gateway"
  depends_on     = [module.LAMBDA-INFO]
  DeploymentName = var.DeploymentName
  lambda_info    = module.LAMBDA-INFO.lambda_info
}
