# Scenario: iam_pmapper

**Size:** Medium

**Difficulty:** Moderate

**Command:** `./cloudgoat.py create iam_pmapper`

## Scenario Resources

- 102 IAM Users
- 1 IAM Role
- 1 IAM Policy

## Scenario Start(s)

1. AWS Access Key and Secret Key for the `pentest` user

## Scenario Goal(s)

Identify the user path and exploit a Lambda PassRole vector to gain administrator access.

## Summary

In this scenario, you start with the credentials of the `pentest` user. This user has low privileges but can perform some basic IAM actions. Using IAM enumeration (e.g. Principal Mapper / pmapper or manual cli enumeration), you must find an intermediate user (`lambda_developer`) from among a large group of decoy users, compromise or escalate to them, and then use `lambda:CreateFunction` and `iam:PassRole` permissions to escalate privileges to administrator.

## Exploitation Route

A detailed cheat sheet & walkthrough for this route is available [here](./cheat_sheet.md).
