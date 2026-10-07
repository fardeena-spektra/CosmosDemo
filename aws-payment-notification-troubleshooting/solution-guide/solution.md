# PAYNOTIFY Payment Notification Troubleshooting — Facilitator Solution

## Use of this guide

This is facilitator-only material. It describes the seeded faults, the expected repair state, console actions, manual checks, and grading. The candidate should work in the AWS console first and should not be given this file. The deployment is in **us-east-1**. Resource names must be taken from the Environment tab; do not substitute a bucket or Lambda function from another deployment.

The package provisions only the reference resources: one VPC/public subnet and VM, one statements bucket, and one notification Lambda. It does **not** provision `pn-statements-archive`.

## Global checks before assisting a candidate

- Confirm the candidate is using the AWS account and `us-east-1` shown by CloudLabs.
- Confirm the injected values are deployment-specific:
  - `StatementsBucket`: `pn-statements-<deploymentid>-<accountid>`
  - `LambdaFunctionName`: `pn-notify-<deploymentid>`
- Confirm CloudFormation bootstrap has completed before using the Windows VM. EC2 state and SSM Agent readiness can lag instance creation; do not treat a temporary RDP/SSM delay as a learner fault.
- The learner uses the AWS credentials supplied in the Environment tab. The learner policy intentionally does not grant CloudFormation deployment or broad IAM administration.
- AWS IAM policy changes can take a short time to propagate. If the role policy is correct but the first invocation still fails with `AccessDenied`, wait briefly and retry.

---

## Exercise 1 — Repair the PAYNOTIFY Statements Bucket

### Seeded faults

The deployed `StatementsBucket` has:

1. All four S3 Block Public Access settings disabled.
2. Versioning disabled.
3. A bucket policy named `FreezeStatementUploads` with an explicit deny for `s3:PutObject` under `statements/*`.
4. No usable `statements/test-statement.txt` object.

The intended repair is a private, versioned bucket with the seeded deny policy removed and the test statement uploaded under the `statements/` prefix.

### Exact AWS Console repair sequence

1. From the AWS console, select **S3** and verify the Region is **US East (N. Virginia) / us-east-1**.
2. Open the bucket whose name equals the Environment-tab `StatementsBucket` value. Do not search for or create `pn-statements-archive`.
3. Open **Permissions**. In **Block public access (bucket settings)**, choose **Edit**, select all four settings, acknowledge the confirmation, and save. The four settings are:
   - Block public access to buckets and objects granted through new access control lists (ACLs).
   - Block public access to buckets and objects granted through any access control lists (ACLs).
   - Block public access to buckets and objects granted through new public bucket or access point policies.
   - Block public access to buckets and objects through any public bucket or access point policies.
4. Remain on the bucket **Properties** tab. In **Bucket Versioning**, choose **Edit**, select **Enable**, and save.
5. Return to **Permissions**. In **Bucket policy**, select **Delete**, confirm the deletion, and verify the policy editor is empty. This removes the seeded `FreezeStatementUploads` explicit deny; do not attempt to edit it into an allow policy.
6. On the Windows VM, open Notepad, enter a small non-empty statement such as `PAYNOTIFY test statement`, and save it to the Desktop as `test-statement.txt`. Ensure Notepad does not append `.txt` a second time.
7. In the bucket **Objects** tab, choose **Create folder**, enter `statements`, and create it. Open that folder, choose **Upload**, add the VM's `test-statement.txt`, and complete the upload.
8. Refresh the folder and verify the object key is exactly `statements/test-statement.txt`.

### Expected validation outcome

The bucket validator succeeds only when all conditions are true:

- The deployment bucket exists.
- All four Block Public Access flags are true.
- Versioning status is `Enabled`.
- No remaining bucket-policy statement denies `s3:PutObject` for the statement path.
- `statements/test-statement.txt` exists.

A successful console upload alone is not sufficient for full credit if the security settings or policy are still wrong. The expected CloudLabs result is the congratulations/validation block with a successful Exercise 1 validation.

### Manual AWS CLI verification

Run these commands with credentials that can inspect the resources. The CLI defaults to the current region, so retain `--region us-east-1`.

```bash
export AWS_REGION=us-east-1
export BUCKET='copy the StatementsBucket value from the Environment tab'

aws s3api get-public-access-block --bucket "$BUCKET" --region "$AWS_REGION"
aws s3api get-bucket-versioning --bucket "$BUCKET" --region "$AWS_REGION"
aws s3api get-bucket-policy --bucket "$BUCKET" --region "$AWS_REGION" || true
aws s3api head-object --bucket "$BUCKET" --key statements/test-statement.txt --region "$AWS_REGION"
aws s3api list-objects-v2 --bucket "$BUCKET" --prefix statements/ --region "$AWS_REGION"
```

Expected public-access output has `true` for `BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, and `RestrictPublicBuckets`; versioning returns `Status: Enabled`; `get-bucket-policy` returns no policy; and `head-object` succeeds.

### Rubric

- **Full credit:** all four Block Public Access settings enabled, versioning enabled, `FreezeStatementUploads` removed/no equivalent deny remains, and the exact object key exists. Exercise 1 validator passes.
- **Partial credit:** one or more required settings are correct and the candidate demonstrates the correct repair direction, but any required state is missing. Examples: object uploaded but versioning remains suspended/disabled; policy removed but only three BPA settings enabled; object is at the bucket root rather than under `statements/`.
- **No completion credit:** candidate creates a different bucket, creates the prohibited archive bucket, or cannot produce the required object and bucket state.

### Common pitfalls

- Working in a different Region or account; S3 bucket names are global, but the bucket must be accessed in the deployment Region.
- Selecting only one BPA checkbox. All four are required.
- Looking for versioning under Permissions instead of Properties.
- Trying to upload before deleting the explicit deny; an explicit deny overrides an allow.
- Uploading `test-statement.txt.txt`, uploading to the root, or using `statements\` rather than the S3 key prefix `statements/`.
- Accidentally deleting the bucket instead of the bucket policy. The bucket must remain.

---

## Exercise 2 — Repair the PAYNOTIFY Notification Function

### Seeded faults

The deployed `pn-notify-<deploymentid>` function is Python 3.12 and contains a function named `lambda_handler`, but:

1. Its handler is incorrectly set to `index.handler`.
2. `BUCKET_NAME` is set to nonexistent `pn-statements-archive`.
3. Its execution role has no permission to perform `s3:PutObject`.

The expected function writes `notifications/latest.json` to the repaired statements bucket.

### Exact AWS Console repair sequence

1. Open **Lambda**, select the function named by the Environment-tab `LambdaFunctionName`, and verify **us-east-1**.
2. On the **Test** tab, create/select a test event named `pn-test`. Use valid JSON exactly or equivalently:

   ```json
   {"customer":"demo-customer"}
   ```

   Invoke it once before repair. The seeded invocation is expected to fail: the initial handler does not match the source function. Capture the error for troubleshooting evidence; do not change the test payload.
3. Open **Code**, then **Runtime settings**, choose **Edit**, change the handler from `index.handler` to `index.lambda_handler`, and save.
4. Open **Configuration > Environment variables**, choose **Edit**, and change the value of `BUCKET_NAME` to the exact injected `StatementsBucket` value. Preserve the variable name and save.
5. In **Configuration > Permissions**, select the execution role link. IAM opens the role in a new page/tab. Under **Permissions policies**, choose **Add permissions > Create inline policy**.
6. In the policy editor, use the JSON view and create the inline policy named `pn-notify-s3-write` with this least-privilege policy. Replace the bucket-name text with the actual bucket name; do not include angle brackets in the ARN:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "WriteNotifications",
         "Effect": "Allow",
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::BUCKET_NAME/notifications/*"
       }
     ]
   }
   ```

   Review the policy, set the name to `pn-notify-s3-write`, and create it. This is an inline policy on the Lambda execution role, not a bucket policy and not a policy on `TaskExecutionRole` or `SSMRole`.
7. Return to Lambda. On **Test**, select `pn-test` and invoke again. A successful invocation should show a completed execution and a function result rather than a handler or S3 `AccessDenied` error. If the policy was just created, wait for IAM propagation and retry.
8. Open the statements bucket in S3, refresh **Objects**, open/create the `notifications` prefix as displayed, and confirm `latest.json` exists. The exact key is `notifications/latest.json`.

### Expected validation outcome

The Lambda validator succeeds only when all of the following are true:

- Function handler is exactly `index.lambda_handler`.
- `BUCKET_NAME` equals the deployment's actual statements bucket.
- The Lambda execution role allows `s3:PutObject` on the deployment bucket's `notifications/latest.json` (the supplied `notifications/*` policy covers it).
- A validator invocation succeeds.
- `notifications/latest.json` exists in the statements bucket.

The notification object may be overwritten by subsequent successful invocations; existence is the required outcome. Exercise 1 should be complete first because the function writes to that bucket.

### Manual AWS CLI verification

```bash
export AWS_REGION=us-east-1
export FUNCTION='copy the LambdaFunctionName value from the Environment tab'
export BUCKET='copy the StatementsBucket value from the Environment tab'

aws lambda get-function-configuration \
  --function-name "$FUNCTION" --region "$AWS_REGION" \
  --query '{Handler:Handler,Environment:Environment.Variables,Role:Role,Runtime:Runtime}'

aws lambda invoke --function-name "$FUNCTION" --region "$AWS_REGION" \
  --payload '{"customer":"demo-customer"}' /tmp/pn-test-response.json
cat /tmp/pn-test-response.json
aws s3api head-object --bucket "$BUCKET" --key notifications/latest.json --region "$AWS_REGION"
```

To inspect the role's inline policy, obtain the role name from the `Role` ARN returned above and use:

```bash
ROLE_ARN=$(aws lambda get-function-configuration --function-name "$FUNCTION" --region "$AWS_REGION" --query Role --output text)
ROLE_NAME=${ROLE_ARN##*/}
aws iam list-role-policies --role-name "$ROLE_NAME"
aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name pn-notify-s3-write
```

The policy resource should be the actual bucket's `notifications/*` ARN. A successful Lambda invoke command can still return a function-level error in its response file, so inspect both the command status and `/tmp/pn-test-response.json`.

### Rubric

- **Full credit:** handler, environment variable, and execution-role permission are corrected; the `pn-test` event completes successfully; `notifications/latest.json` exists; Exercise 2 validator passes.
- **Partial credit:** one or two configuration corrections are made or the candidate demonstrates a valid least-privilege policy, but invocation or object validation is incomplete. Examples: handler fixed but old archive bucket remains; correct bucket configured but policy targets the bucket root or wrong bucket; invocation succeeds but no notification object is present.
- **No completion credit:** candidate creates `pn-statements-archive`, changes the function to a different handler not present in the source, grants unrelated broad IAM access, or edits the wrong execution role.

### Common pitfalls

- Editing **Runtime** instead of the handler field in **Runtime settings**.
- Using `lambda_handler` without the module prefix; the required value is `index.lambda_handler`.
- Leaving the old archive value in the environment variable. The archive bucket is intentionally nonexistent and must not be created.
- Attaching `s3:PutObject` to the wrong role, using a bucket ARN without `/*`, or using an ARN for the wrong bucket.
- Expecting a Lambda environment-variable change or IAM role-policy update to apply instantly. Save, wait briefly, and invoke again.
- Reading only the console's invocation status and not checking the returned function error or the S3 object.
- S3 Block Public Access is unrelated to same-account Lambda role authorization; do not make the bucket public to fix this task.

---

## Exercise 3 — Review the PAYNOTIFY Network Basics

Exercise 3 is six single-choice questions, **2 marks each**, for **12 marks total**. One retry is allowed per question. Grade against the option text in the corresponding candidate question, not merely the option position. The correct concepts and rationale are:

| Question topic | Correct answer concept | Rationale |
|---|---|---|
| 1. VPC CIDR and subnet scope | A subnet is a subdivision of a VPC CIDR and exists entirely within one Availability Zone; VPCs provide the regional network boundary. | A subnet cannot span multiple Availability Zones, and its CIDR must be contained within the VPC CIDR without overlapping another subnet in that VPC. |
| 2. Public versus private subnet | A subnet is public only when its route table has a route to an Internet Gateway and the resource has a public IPv4 address or equivalent public path. | The subnet name alone does not make it public. A private subnet has no direct Internet Gateway route; its instances can use a NAT gateway for outbound access when routing and security permit. |
| 3. Security groups versus network ACLs | Security groups are stateful, instance/ENI-level allow lists; network ACLs are stateless, subnet-level filters that support allow and deny rules. | Return traffic is automatically allowed by a security group for an allowed flow. NACL return traffic must be permitted separately, including appropriate ephemeral ports. |
| 4. Internet Gateway and public routing | A VPC must have an Internet Gateway attached, and the subnet route table must contain a default route such as `0.0.0.0/0` to that gateway for direct Internet access. | A public IPv4 address without the attachment and route is not enough. The route table associated with the subnet is the one that controls the path. |
| 5. NAT Gateway purpose | A NAT gateway lets instances in a private subnet initiate outbound IPv4 connections through a public subnet/Internet Gateway; it does not provide unsolicited inbound Internet access. | The private subnet needs a default route to the NAT gateway, and the NAT gateway needs a public-subnet route to an Internet Gateway. NAT gateways are AZ-specific resources for routing design and availability. |
| 6. DNS/routing troubleshooting | Check VPC DNS support/hostnames and the effective route table associated with the subnet; a route table is selected by the subnet association, with the main route table used only when there is no explicit association. | DNS settings affect name resolution; route-table association affects packet forwarding. A route in an unassociated table does not fix traffic from the subnet. |

### Scoring rubric

- **12/12:** all six concepts answered correctly, with the one permitted retry used where necessary.
- **10/12, 8/12, 6/12, 4/12, 2/12:** five, four, three, two, or one correct answers respectively; each correct answer is 2 marks.
- **0/12:** no correct answers or no submission.
- Do not award marks for a technically adjacent explanation when the selected single-choice answer contradicts the keyed concept. Do not penalize a learner for choosing a correct answer on the retry.

### Facilitator clarifications

- The deployed VM is in the reference public subnet (`10.10.1.0/24`) within VPC `10.10.0.0/16`; these details are useful context but are not evidence that a candidate can skip the question concepts.
- Security groups are not NACLs, and an Internet Gateway is not a NAT gateway. Keep those distinctions explicit when reviewing answers.
- The questions are independent of the intentionally broken S3 and Lambda resources. Do not reveal an answer by pointing the learner to the seeded faults.

---

## Overall completion decision

A complete lab requires both technical validators to succeed **and** all six networking questions to be answered according to the key. Record Exercise 1 and Exercise 2 as validator-gated outcomes; record Exercise 3 as 12 marks. For a partial-progress review, report the missing bucket condition, Lambda condition, object key, or question number rather than awarding completion based on a console screenshot alone.

### Fast final check

```bash
# S3 final state
aws s3api get-public-access-block --bucket "$BUCKET" --region us-east-1
aws s3api get-bucket-versioning --bucket "$BUCKET" --region us-east-1
aws s3api head-object --bucket "$BUCKET" --key statements/test-statement.txt --region us-east-1
aws s3api head-object --bucket "$BUCKET" --key notifications/latest.json --region us-east-1

# Lambda final state
aws lambda get-function-configuration --function-name "$FUNCTION" --region us-east-1 \
  --query '{Handler:Handler,Variables:Environment.Variables}'
```

The final state must show the four BPA controls enabled, versioning enabled, no seeded deny policy, both required object keys, handler `index.lambda_handler`, and `BUCKET_NAME` equal to the deployment statements bucket.