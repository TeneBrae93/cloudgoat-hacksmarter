resource "aws_secretsmanager_secret" "flag" {
  name        = "cg-flag-${var.cgid}"
  description = "CloudGoat flag secret"
}

resource "aws_secretsmanager_secret_version" "flag_val" {
  secret_id     = aws_secretsmanager_secret.flag.id
  secret_string = "HSM{l4mbd4_pr1v3sc_4dm1n_v1ct0ry}"
}