# Scenario: iam_pmapper Walkthrough

## Summary

In this scenario, you start as the `pentest` user, who has `IAMReadOnlyAccess` and permissions to create access keys on any user. You must identify the target user among 100 decoy users by enumerating their permissions, generate access keys for them, and then leverage their Lambda function creation and role-passing permissions to run a malicious function that executes with admin privileges. To complete the lab, retrieve the admin flag stored in AWS Secrets Manager.

## Detailed Walkthrough

1. **Enumerate current user (`pentest`):**
   Run the following to check your current caller identity:
   ```bash
   aws sts get-caller-identity
   ```

2. **Check policy details:**
   List the attached and inline policies for the `pentest` user.
   You will find `IAMReadOnlyAccess` attached and an inline policy allowing `iam:CreateAccessKey` on all users (`arn:aws:iam::*:user/*`).

3. **Enumerate other users (pmapper or manual):**
   List all users in the account:
   ```bash
   aws iam list-users
   ```
   You will see 101 random-named users (e.g. `cg-aobqwxzy-lab`). There is no naming pattern to distinguish the target user from the decoys.

4. **Investigate permissions of the users:**
   Inspect the inline policies and attached policies of the users. You can use Principal Mapper (`pmapper`) to automate this search, or write a loop in AWS CLI.
   You will find that only one target user has permissions:
   * `lambda:CreateFunction`
   * `lambda:InvokeFunction`
   * `iam:PassRole` on `arn:aws:iam::*:role/cg-LambdaAdminExecutionRole-...`

5. **Compromise the target user:**
   Since you have `iam:CreateAccessKey` permissions on all users, generate a new access key for the target user you identified:
   ```bash
   aws iam create-access-key --user-name [TARGET-USER-NAME]
   ```

6. **Create a vulnerable/malicious Lambda Function:**
   Configure AWS CLI with the new credentials of the target user. Then, write a simple Lambda function deployment package (e.g. Python script to attach AdministratorAccess policy or run actions).
   Create a zip containing your code:
   ```bash
   zip function.zip lambda_function.py
   ```
   Create the function using the target user's permissions, passing the `cg-LambdaAdminExecutionRole` role:
   ```bash
   aws lambda create-function --function-name admin_shell \
     --runtime python3.9 --role [cg-LambdaAdminExecutionRole-ARN] \
     --handler lambda_function.lambda_handler \
     --zip-file fileb://function.zip
   ```

7. **Escalate privileges and retrieve the flag:**
   Invoke the function:
   ```bash
   aws lambda invoke --function-name admin_shell output.txt
   ```
   Verify the function executed successfully. You can use your administrative access (via the assumed role or by creating an admin user/credential) to read the secret flag stored in AWS Secrets Manager:
   ```bash
   aws secretsmanager get-secret-value --secret-id cg-admin-flag-[cgid]
   ```
