output "access_key" {
  value = aws_iam_access_key.sqs.id
}

output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.sqs.secret)
  sensitive = false
}

output "web_site_ip" {
  value = "http://${aws_instance.flag_shop_server.public_ip}:5000"
}
