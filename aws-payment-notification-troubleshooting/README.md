# AWS Payment Notification Troubleshooting

## Summary

This 90-minute intermediate AWS assessment places the learner in the role of the on-call cloud engineer for the fintech PAYNOTIFY payment-notification service. After a change window, the service is failing because its S3 statements bucket and notification Lambda are deliberately misconfigured.

The learner works from a Windows Server 2022 VM accessed through the CloudLabs RDP-over-HTTPS environment. Using Microsoft Edge and the AWS Management Console in `us-east-1`, the learner repairs the bucket security and upload path, repairs the Lambda handler, environment variable, and S3 write permission, invokes the function successfully, verifies the notification object, and completes six networking questions.

## Environment and deployment

- Cloud: AWS
- Region: `us-east-1`
- Deployment stages: one CloudFormation deployment stage
- Deployment template: `DeploymentPackage/deploy-01.json`
- Parameters: `DeploymentPackage/deploy-01.parameters.json`
- Access: CloudLabs Environment tab credentials and a Windows Server 2022 VM over RDP over HTTPS
- VM tooling: Microsoft Edge, Notepad, AWS Management Console shortcut, and AmazonSSMAgent configured by the reference UserData

The CFT provisions one VPC (`10.10.0.0/16`), one public subnet (`10.10.1.0/24`), internet gateway, route table, learner VM security group, the reference `clgSg`, a t3-family Windows VM, IAM/SSM plumbing, one statements bucket, and one Python 3.12 Lambda function. The bucket name is `pn-statements-<deploymentid>-<accountid>` and the function name is `pn-notify-<deploymentid>`.

No `pn-statements-archive` bucket is created. The archive name is only the seeded, invalid Lambda environment value that the learner must replace. No Bash validator or AWS CLI validator is included, and no standalone CSE/psscript artifact is generated; the reference CFT embedded UserData is retained as-is, including the final AmazonSSMAgent restart.

## Exercises

1. **Repair the PAYNOTIFY Statements Bucket** — enable all four S3 Block Public Access settings, enable versioning, remove the seeded `FreezeStatementUploads` deny policy, and upload `statements/test-statement.txt`.
2. **Repair the PAYNOTIFY Notification Function** — change the handler to `index.lambda_handler`, set `BUCKET_NAME` to the injected statements bucket, add the scoped `pn-notify-s3-write` permission, run the `pn-test` event, and verify `notifications/latest.json`.
3. **Review the PAYNOTIFY Network Basics** — answer six single-choice networking questions covering VPCs/subnets, security groups/NACLs, internet/NAT gateways, and DNS/routing.

## Inject keys

Guides expose only these required CloudLabs inject keys:

- `Region`
- `CloudLabsDeploymentID`
- `StatementsBucket`
- `LambdaFunctionName`
- `VMUserName`
- `VMPassword`

The CloudFormation template also emits the complete reference output set: `CloudLabsDeploymentID`, `AWSAccountID`, `Region`, `VpcId`, `vmSubnetId`, `vmSecurityGroupId`, `clusterSecurityGroupId`, `TaskExecutionRole`, `InstanceId`, `VMName`, `VMPublicIP`, `VMPrivateIP`, `VMPublicDNSName`, `VMPrivateDNSName`, `VMUserName`, `VMPassword`, `StatementsBucket`, and `LambdaFunctionName`.

## Assessment and validation

There are six simple single-choice questions worth 2 marks each, for 12 marks total, with one retry. Two PowerShell validators use AWS.Tools cmdlets and CloudLabs deployment/region inputs. The S3 validator checks bucket existence, all Block Public Access settings, versioning, removal of the upload deny, and the statement object. The Lambda validator checks configuration, scoped S3 write access, successful invocation, and `notifications/latest.json`.

## Access control artifacts

The package includes a learner-facing AWS IAM custom policy restricted to the S3, Lambda, and Lambda-role inspection/update operations required by the exercises. It does not grant CloudFormation deployment or broad IAM administration. The package also includes the required `us-east-1`-only AWS policy/SCP artifact and preserves the reference tagging rule and exclusions.

## Package contents

- `Spec.md`
- `DeploymentPackage/deploy-01.json`
- `DeploymentPackage/deploy-01.parameters.json`
- Lab guide pages under `LabGuidePackage/Lab Guide/Lab Guide/`
- Six files under `Inline-Questions/`
- Two PowerShell validators under `Validations/`
- `permissions/CustomRBAC/custom-rbac-role.json`
- `permissions/CustomARMPolicy/azure-policy.json`
- `solution-guide/solution.md`

The package follows the approved `cosmos-aws-lab-reference.md` structure, CloudLabs guide conventions, output names, tagging, validator response conventions, and deployment formats.
