data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


variable "DeploymentName" {}


locals {
  BUCKETNAME = lower(join("", [var.DeploymentName, "-artifacts-store"]))
  REPONAME   = var.DeploymentName
  PO         = file("${path.module}/transform.json")
}


resource "aws_s3_bucket" "artifacts_store" {
  bucket = local.BUCKETNAME
}

resource "aws_codecommit_repository" "artifacts_repo" {
  repository_name = var.DeploymentName
  description     = join("", [var.DeploymentName])
}



resource "aws_iam_role" "codebuild-role" {
  name = join("", [var.DeploymentName, "-codebuild-role"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = join("", [var.DeploymentName, "-codebuild-role-inline-policy"])
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Resource" : [join("", ["arn:aws:s3:::", local.BUCKETNAME]), join("", ["arn:aws:s3:::", local.BUCKETNAME, "/", "*"])]
          "Action" : [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject"
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : [
            join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":", "log-group:/aws/codebuild/", var.DeploymentName, "*"]),
            join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":", "log-group:/aws/codebuild/", var.DeploymentName])
          ],

          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}


resource "aws_iam_role" "codepipeline-role" {
  name = join("", [var.DeploymentName, "-codepipeline-role"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = join("", [var.DeploymentName, "-codepipeline-role-inline-policy"])
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Resource" : join(":", ["arn:aws:codecommit", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.REPONAME]),
          "Action" : [
            "codecommit:CancelUploadArchive",
            "codecommit:GetBranch",
            "codecommit:GetCommit",
            "codecommit:GetRepository",
            "codecommit:GetUploadArchiveStatus",
            "codecommit:UploadArchive"
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : join("", ["arn:aws:codebuild:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":project/", var.DeploymentName, "-build"]),
          "Action" : [
            "codebuild:BatchGetBuilds",
            "codebuild:BatchGetBuildBatches",
            "codebuild:StartBuildBatch",
            "codebuild:StartBuild",
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : [join("", ["arn:aws:s3:::", local.BUCKETNAME]), join("", ["arn:aws:s3:::", local.BUCKETNAME, "/", "*"])]
          "Action" : [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject"
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : "*"
          "Action" : [
            "cloudformation:DescribeStacks",
            "cloudformation:CreateStack",
            "cloudformation:UpdateStack",
            "iam:PassRole"
          ]
        }
      ]
    })
  }
}


resource "aws_iam_role" "cloudformation-role" {
  name = join("", [var.DeploymentName, "-cloudformation-role"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = join("", [var.DeploymentName, "-codepipeline-role-inline-policy"])
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Resource" : "*",
          "Action" : [
            "iam:GetRole",
            "iam:DeleteRole",
            #"iam:PassRole",
            "iam:CreateRole",
            "iam:AttachRolePolicy",
            "iam:getRolePolicy",
            "iam:PutRolePolicy",
            "iam:DeleteRolePolicy",
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : "*",
          "Action" : [
            "lambda:GetFunctionCodeSigningConfig",
            "lambda:GetFunction",
            "lambda:UpdateFunctionCode",
            "lambda:UpdateFunctionConfiguration",
            "lambda:PutFunctionConcurrency",
            "lambda:CreateFunction",
            "lambda:DeleteFunction",
            "lambda:PublishVersion",
            "lambda:ListVersionsByFunction",
            "lambda:ListTags"
          ]
        },
        {
          "Effect" : "Allow",
          "Resource" : [join("", ["arn:aws:s3:::", local.BUCKETNAME]), join("", ["arn:aws:s3:::", local.BUCKETNAME, "/", "*"])],
          "Action" : [
            "s3:GetObject"
          ]
        }

      ]
    })
  }
}



resource "aws_codebuild_project" "lambda-builder" {
  name          = join("", [var.DeploymentName, "-build"])
  description   = join("", ["CodeBuild Builder Project for ", var.DeploymentName])
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild-role.arn
  source {
    type = "CODEPIPELINE"
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type = "NO_CACHE"
  }
  environment {
    # compute_type = "BUILD_GENERAL1_SMALL"
    compute_type = "BUILD_GENERAL1_LARGE"
    ##################
    #ARM architecture rules !!!
    image = "aws/codebuild/amazonlinux2-aarch64-standard:2.0"
    ##################
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    environment_variable {
      name  = "DEPLOYMENTNAME"
      value = var.DeploymentName
    }
    environment_variable {
      name  = "BUCKET"
      value = local.BUCKETNAME
    }
  }
}


resource "aws_codepipeline" "lambda-pipeline" {
  name     = join("", [var.DeploymentName, "-pipeline"])
  role_arn = aws_iam_role.codepipeline-role.arn
  artifact_store {
    location = local.BUCKETNAME
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        RepositoryName = local.REPONAME
        BranchName     = "PROD"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      configuration = {
        ProjectName = join("", [var.DeploymentName, "-build"])
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ActionMode         = "CREATE_UPDATE"
        RoleArn            = aws_iam_role.cloudformation-role.arn
        Capabilities       = "CAPABILITY_IAM,CAPABILITY_NAMED_IAM"
        OutputFileName     = "CreateStackOutput.json"
        StackName          = join("", [var.DeploymentName, "-stack"])
        TemplatePath       = "BuildArtifact::cf/deploy_stack.yaml"
        ParameterOverrides = tostring(local.PO)
      }
    }
  }

}
