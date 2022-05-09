
variable "DeploymentName" {}


resource "aws_cloudformation_stack" "lambda-init-stack" {
  name         = join("", [var.DeploymentName, "-stack"])
  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    DeploymentName = var.DeploymentName
  }

  template_body = <<STACK
      Parameters:

        DeploymentName:
          Type: String

      Resources:
        LambdaRole:
          Type: 'AWS::IAM::Role'
          Properties:
            RoleName: !Join
              - ''
              - - !Ref DeploymentName
                - -Lambda-Role
            AssumeRolePolicyDocument:
              Version: 2012-10-17
              Statement:
                - Effect: Allow
                  Principal:
                    Service:
                      - lambda.amazonaws.com
                  Action:
                    - 'sts:AssumeRole'
            Path: /
            Policies:
              - PolicyName: !Join
                  - ''
                  - - !Ref DeploymentName
                    - -Lambda-Policy
                PolicyDocument:
                  Version: 2012-10-17
                  Statement:
                    - Effect: Allow
                      Action:
                        - 'logs:CreateLogStream'
                        - 'logs:PutLogEvents'
                      Resource: !Join
                        - ''
                        - - 'arn:aws:logs:'
                          - !Ref 'AWS::Region'
                          - ':'
                          - !Ref 'AWS::AccountId'
                          - ':log-group:/aws/lambda/'
                          - !Ref DeploymentName
                          - '-Lambda:*'
                    - Effect: Allow
                      Action:
                        - 'logs:CreateLogGroup'
                      Resource: !Join
                        - ''
                        - - 'arn:aws:logs:'
                          - !Ref 'AWS::Region'
                          - ':'
                          - !Ref 'AWS::AccountId'
                          - ':*'





        LambdaFunction:
            Type: 'AWS::Lambda::Function'
            DependsOn: LambdaRole
            Properties:
              Architectures: ['arm64']
              FunctionName: !Join [ "", [ !Ref DeploymentName , '-Lambda' ] ]
              Handler: lambda_function.lambda_handler
              Role: !GetAtt LambdaRole.Arn
              Code:
                ZipFile: |
                    import json
                    def lambda_handler(event, context):
                        return ('Hello from dummy')
              Runtime: python3.8
              Timeout: 30
              ReservedConcurrentExecutions: 100
STACK
}
