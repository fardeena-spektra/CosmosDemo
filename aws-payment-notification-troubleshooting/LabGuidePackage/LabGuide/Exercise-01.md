# Exercise 1: Repair the PAYNOTIFY Statements Bucket

## Overview

In this exercise, you are the on-call cloud engineer for the PAYNOTIFY payment-notification service. A change-window update left the statements bucket with unsafe access settings and a policy that prevents statement uploads. Restore the bucket configuration, remove the upload block, and prove that a statement can be uploaded to the required prefix.

> **Objective:** Turn on all Amazon S3 Block Public Access settings, enable versioning, remove the `FreezeStatementUploads` bucket policy, and upload `statements/test-statement.txt`.

## Scenario

**Service owner:** The payment team reports that a new customer statement cannot be placed in the statements bucket.

**On-call engineer:** “I will inspect the bucket settings and policy first. I will make the bucket private, preserve object versions, remove the deliberate upload deny, and then test the expected `statements` path.”

**Service owner:** “Please use the bucket created for this deployment and confirm the test object is visible under the `statements` folder.”

The seeded bucket has all four Block Public Access settings turned off, versioning disabled, and a bucket policy named `FreezeStatementUploads` that denies `s3:PutObject` for objects under `statements/*`.

## Sign in to AWS

1. From the CloudLabs VM, open Microsoft Edge and select the AWS Management Console shortcut on the desktop. If you need to sign in manually, open <inject key="AwsConsoleUrl"/> and enter the supplied IAM user name <inject key="IamUserName"/> and password <inject key="IamUserPassword"/>.
2. In the AWS console, confirm the Region selector is **US East (N. Virginia) us-east-1**. Use the CloudLabs Environment tab for the credentials and resource values supplied for this lab.

> **Image placeholder:** AWS console sign-in and the us-east-1 Region selector.

## Repair the statements bucket

### 1. Open the deployment bucket

**(1)** In the AWS console search bar, search for **S3**, and choose **S3** from the results.

**(2)** On the S3 **General purpose buckets** page, select the bucket value supplied by CloudLabs: <inject key="StatementsBucket" enableCopy="true"/>.

**(3)** Keep the bucket page open. You will use the **Permissions** and **Properties** tabs to repair the seeded configuration.

> **Image placeholder:** The deployed `StatementsBucket` selected on the S3 General purpose buckets page.

### 2. Turn on all Block Public Access settings

**(1)** Select the **Permissions** tab and locate **Block public access (bucket settings)**.

**(2)** Choose **Edit**, select **Block all public access**, and choose **Save changes**. This enables the four underlying settings: **Block public ACLs**, **Ignore public ACLs**, **Block public bucket policies**, and **Restrict public buckets**.

**(3)** When prompted to confirm, enter `confirm` if requested and choose **Confirm**. Reopen the section and verify that all four settings show **On**.

> **Image placeholder:** Block public access settings showing all four controls enabled.

### 3. Enable bucket versioning

**(1)** Select the **Properties** tab and scroll to **Bucket Versioning**.

**(2)** Choose **Edit**, select **Enable**, and choose **Save changes**.

**(3)** Confirm the Bucket Versioning section shows **Bucket Versioning: Enabled**. Versioning helps retain and recover prior object versions when a statement is replaced or deleted.

> **Image placeholder:** Bucket Versioning showing Enabled.

### 4. Delete the seeded bucket policy

**(1)** Return to the **Permissions** tab and scroll to **Bucket policy**.

**(2)** Review the policy and verify that its statement is named `FreezeStatementUploads` and denies `s3:PutObject` for the `statements/*` path.

**(3)** Choose **Delete**, confirm the deletion when prompted, and verify that no bucket policy remains. Do not create a replacement public policy.

> **Image placeholder:** Bucket policy section after `FreezeStatementUploads` has been deleted.

### 5. Create the test statement on the Windows VM

**(1)** On the CloudLabs Windows VM desktop, open **Notepad** from the Start menu.

**(2)** Enter a short test value such as `PAYNOTIFY test statement`.

**(3)** Choose **File > Save as**, select **Desktop**, set **File name** to `test-statement.txt`, set **Save as type** to **All files**, and choose **Save**. Confirm that `test-statement.txt` appears on the desktop.

> **Image placeholder:** Notepad containing the test statement and `test-statement.txt` saved on the desktop.

### 6. Create the statements folder and upload the file

**(1)** Return to the S3 bucket page and select the **Objects** tab. Choose **Create folder**, enter `statements`, and choose **Create folder**. If the folder already exists, open it instead.

**(2)** Open the `statements` folder, choose **Upload**, choose **Add files**, select `test-statement.txt` from the VM desktop, and choose **Upload**.

**(3)** Wait for the upload to complete, choose **Close**, and verify that `test-statement.txt` is listed in the `statements` folder. The object key must be `statements/test-statement.txt`.

> **Image placeholder:** Successful upload showing `test-statement.txt` inside the `statements` folder.

## Congratulations!

You have repaired the PAYNOTIFY statements bucket when all of the following are true:

- All four Block Public Access settings are enabled.
- Bucket versioning is enabled.
- The `FreezeStatementUploads` bucket policy has been deleted.
- `statements/test-statement.txt` is present in the deployed bucket.

<div class="cloudlabs-validate">

**Validate your work**

Select **Validate** to check the complete bucket repair. The validation checks the bucket settings, versioning state, removal of the upload-deny policy, and the uploaded statement object.

<validation step="01b7992c-38d6-45be-835b-8f81b75fa69f"/>


If validation reports a missing item, return to the relevant S3 tab, correct it, and select **Validate** again.

## Summary

In this exercise, you used the Amazon S3 console to restore bucket security and upload behavior. You enabled all Block Public Access settings, enabled versioning, removed the seeded `FreezeStatementUploads` deny policy, created `test-statement.txt` in Notepad, and uploaded it as `statements/test-statement.txt`. Continue to Exercise 2 to repair the PAYNOTIFY notification function.
