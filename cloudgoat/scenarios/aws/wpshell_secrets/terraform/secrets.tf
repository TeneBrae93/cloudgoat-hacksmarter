resource "aws_secretsmanager_secret" "final_flag" {
  name        = "cg-final-flag-${var.cgid}"
  description = "CloudGoat Final Flag"
}

resource "aws_secretsmanager_secret_version" "final_flag_value" {
  secret_id     = aws_secretsmanager_secret.final_flag.id
  secret_string = "HSM{369817da90b44eb9aacc1ccf592d3fd1}"
}
