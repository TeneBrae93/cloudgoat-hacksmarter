# Scenario: wpshell_secrets

**Size:** Medium

**Difficulty:** Moderate

**Command:** `$ ./cloudgoat.py create wpshell_secrets`

## Scenario Resources

- 1 VPC with:
	- EC2 x 1 (WordPress Web Server)
- 1 Lambda Function
- 1 S3 Bucket
- 1 Secrets Manager Secret
- 3 IAM Users (`pentest`, `lambda-manager`, `wp-manager`)
- 1 IAM Role (`ec2-role`)

## Scenario Start(s)

1. IAM User "pentest"

## Scenario Goal(s)

Retrieve the flag stored in AWS Secrets Manager.

## Summary

Starting as the IAM user `pentest`, the attacker discovers they can retrieve information about Lambda functions in the account. In the environment variables of one Lambda function, they find credentials for the user `lambda-manager`. Using these credentials, they access an S3 bucket that contains a deployment script with hardcoded credentials for `wp-manager`. With `wp-manager`'s permissions, they identify an EC2 instance running a WordPress website. The WordPress website is vulnerable to the `wp2shell` exploit chain. Exploiting this site gives them Remote Code Execution (RCE). From the container, they query the Instance Metadata Service (IMDS) to steal the temporary credentials of the IAM role `ec2-role` attached to the instance. Finally, they use this role to retrieve the secret flag from AWS Secrets Manager.

## Exploitation Route(s)

```
[pentest] -> Enumerate Lambda env vars -> [lambda-manager] -> Enumerate S3 script -> [wp-manager] -> Enumerate EC2 instances -> Exploit WordPress (wp2shell RCE) -> IMDS Abuse -> [ec2-role] -> Read Secret -> [Flag]
```

## Route Walkthrough - IAM User "pentest"

1. Configure the AWS CLI using the starting credentials for the `pentest` user.
2. Enumerate Lambda functions and find `cg-log-processor-[ CloudGoat ID ]`. Get its environment variables to retrieve access keys for `lambda-manager`.
3. Configure the `lambda-manager` profile. Discover and list the `cg-engineering-scripts-[ CloudGoat ID ]` S3 bucket, then download `deployment-script.sh`.
4. Inspect the downloaded script to find hardcoded credentials for the `wp-manager` user.
5. Configure the `wp-manager` profile and enumerate EC2 instances, finding the public IP of the `cg-marketing-wp-[ CloudGoat ID ]` server.
6. Visit the WordPress website on the public IP. Exploit the REST API batch endpoint route confusion and SQL injection vulnerability chain (`wp2shell`) to execute a reverse shell or run commands.
7. Abuse the Instance Metadata Service (IMDSv1) by calling `http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-role` to retrieve temporary credentials for the `ec2-role`.
8. Configure a profile with the temporary credentials and retrieve the flag `HSM{369817da90b44eb9aacc1ccf592d3fd1}` from AWS Secrets Manager.

A cheat sheet for this route is available [here](./cheat_sheet_pentest.md).
