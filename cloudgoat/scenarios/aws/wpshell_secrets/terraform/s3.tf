data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "engineering_scripts" {
  bucket        = "cg-engineering-scripts-${var.cgid}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_object" "deployment_script" {
  bucket  = aws_s3_bucket.engineering_scripts.id
  key     = "deployment-script.sh"
  content = <<-EOF
#!/bin/bash
# WordPress Deployment and Backup Automation Script
# Authorized access only.

export AWS_ACCESS_KEY_ID="${aws_iam_access_key.wp_manager.id}"
export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.wp_manager.secret}"

echo "Starting WordPress backup job..."
# Backup tasks go here...
echo "Backup completed successfully."
EOF
}
