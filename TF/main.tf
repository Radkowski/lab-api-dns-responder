
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


module "ALB" {
  depends_on     = [module.LAMBDA-INFO]
  source         = "./alb"
  DeploymentName = var.DeploymentName
  CERTARN        = var.CERTARN
  VPCID          = var.VPCID
  SUBNETSID      = var.SubnetsID
  LAMBDA         = module.LAMBDA-INFO.lambda_info
  SSL-ENABLE     = var.SSL-ENABLE
}
