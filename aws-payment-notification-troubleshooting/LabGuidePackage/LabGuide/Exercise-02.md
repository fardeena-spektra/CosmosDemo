# Exercise 2: Repair the PAYNOTIFY Notification Function

## Overview

The PAYNOTIFY notification function is failing after a change window. In this exercise, you will troubleshoot the seeded Lambda configuration, correct its destination bucket, grant the function the least privilege needed to write notifications, and verify the result in Amazon S3.

The function is deliberately misconfigured:

- Its handler is `index.handler`, but the deployed Python source defines `lambda_handler`.
- Its `BUCKET_NAME` environment variable points to the nonexistent `pn-statements-archive` bucket.
- Its execution role does not allow `s3:PutObject`.

**Objective:** restore Lambda execution and its S3 notification write.

## Scenario

> **Incident bridge — PAYNOTIFY on-call:** “The statement upload is available, but the notification record is not being written.”
>
> **You:** “I’ll reproduce the failure with the supplied test event, repair the handler and destination, then add only the required S3 write permission.”
>
> **Incident bridge — PAYNOTIFY on-call:** “After the retest, confirm that the latest notification is present in the statements bucket.”

## Sign in to the AWS console

1. From the CloudLabs Environment tab, open the AWS console using the provided credentials. If you are signing in from the lab VM, open the AWS console shortcut in Microsoft Edge.
2. Use the AWS console URL <inject key="AwsConsoleUrl"></inject>, user name <inject key="IamUserName"></inject>, and password <inject key="IamUserPassword"></inject>.
3. Confirm that the Region selector is set to `us-east-1` (N. Virginia), then open **Lambda**.

## Repair the function

### 1. Open the seeded Lambda function

1. In the AWS console search bar, search for **Lambda**, and choose **Lambda**.
2. In the left navigation pane, choose **Functions**.
3. Open the function named <inject key="LambdaFunctionName" enableCopy="true"></inject>.

![Image placeholder: Lambda Functions list showing the injected PAYNOTIFY function](images/exercise-02-01.png)

### 2. Create and run the `pn-test` test event

1. On the function page, choose the **Test** tab. If no test event is available, choose **Create new event**.
2. Set the event name to `pn-test`. Keep the event private to this account if the console presents that option.
3. Replace the event JSON with the following payload, then choose **Save** and **Test**.

```json
{"customer":"demo-customer"}
```

The initial invocation is expected to fail because the handler is seeded as `index.handler` while the source defines `lambda_handler`. Review the execution result and error details before continuing.

![Image placeholder: Lambda Test tab with the pn-test event and the initial failed result](images/exercise-02-02.png)

### 3. Correct the handler

1. Choose the **Configuration** tab, then choose **Runtime settings**.
2. Choose **Edit**.
3. Change **Handler** from `index.handler` to `index.lambda_handler`, choose **Save**, and wait for the configuration update to complete.

![Image placeholder: Runtime settings showing handler index.lambda_handler](images/exercise-02-03.png)

### 4. Correct the `BUCKET_NAME` environment variable

1. Still on the function page, open **Configuration**, then choose **Environment variables**.
2. Choose **Edit** and locate the variable named `BUCKET_NAME`.
3. Replace its value with the actual statements bucket name: <inject key="StatementsBucket" enableCopy="true"></inject>. Choose **Save**.

Do not create or use `pn-statements-archive`; the lab has one statements bucket.

![Image placeholder: Environment variables showing BUCKET_NAME set to the injected statements bucket](images/exercise-02-04.png)

### 5. Add the least-privilege inline policy

1. Open the **Configuration** tab and choose **Permissions**. In **Execution role**, choose the linked IAM role name.
2. On the IAM role page, choose **Add permissions**, then choose **Create inline policy**.
3. In the policy editor, choose the **JSON** tab, replace the editor contents with the policy below, and choose **Next**.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "WriteNotifications",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::<STATEMENTS_BUCKET>/notifications/*"
    }
  ]
}
```

Replace `<STATEMENTS_BUCKET>` in the policy with the value shown for <inject key="StatementsBucket" enableCopy="true"></inject>. Do not include angle brackets in the saved ARN. On the review page, set the policy name to `pn-notify-s3-write`, review the single `s3:PutObject` permission, and choose **Create policy**.

![Image placeholder: IAM inline policy editor with the notification PutObject resource](images/exercise-02-05.png)

### 6. Retest the function

1. Return to the Lambda function page and choose the **Test** tab.
2. Select the saved `pn-test` event and choose **Test**.
3. Confirm that the execution result reports **Succeeded**. If the result still shows an error, verify the handler spelling, the exact bucket value, the inline policy name, and the policy resource path before testing again.

![Image placeholder: Successful pn-test Lambda invocation](images/exercise-02-06.png)

### 7. Confirm the notification object in Amazon S3

1. Open **Amazon S3** from the AWS console and choose **Buckets**.
2. Open the bucket named <inject key="StatementsBucket" enableCopy="true"></inject>.
3. Open the `notifications/` folder and confirm that `latest.json` exists. Open the object to inspect its details if required.

![Image placeholder: S3 notifications folder containing latest.json](images/exercise-02-07.png)

## Congratulations!

You repaired the PAYNOTIFY notification path by correcting the Lambda handler, pointing `BUCKET_NAME` to the deployed statements bucket, and granting the execution role only the required notification-object write permission.

> **Validate your work**
>
> Select **Validate** to confirm the corrected handler, bucket setting, execution-role permission, successful invocation, and `notifications/latest.json` object.

<validation step="2" />

## Summary

In this exercise, you:

- Reproduced the seeded Lambda failure with the `pn-test` event.
- Changed the handler to `index.lambda_handler`.
- Changed `BUCKET_NAME` to the injected statements bucket.
- Added the `pn-notify-s3-write` inline policy for `s3:PutObject` on `notifications/*`.
- Retested the function and confirmed `notifications/latest.json` in Amazon S3.
