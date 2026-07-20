data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "cg-ec2-sg-${var.cgid}"
  description = "Security Group for WordPress marketing server"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cg-ec2-sg-${var.cgid}"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh_public_key)
}

resource "aws_instance" "wordpress" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium" # Using medium for docker running MariaDB + WordPress comfortably
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # Enable IMDSv1
    http_put_response_hop_limit = 2          # Hop limit >= 2 to allow access from inside docker container
  }

  user_data = <<-EOF
#!/bin/bash
# Update and install Docker
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io curl
systemctl start docker
systemctl enable docker

# Run MariaDB
docker run -d --name wordpress-db --restart always \
  -e MYSQL_ROOT_PASSWORD=cloudgoat_root_pass \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wordpress \
  -e MYSQL_PASSWORD=cloudgoat_wp_pass \
  mariadb:10.5

# Run WordPress 6.9.0
docker run -d --name wordpress --restart always \
  --link wordpress-db:mysql \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=cloudgoat_wp_pass \
  -e WORDPRESS_DB_NAME=wordpress \
  -p 80:80 \
  wordpress:6.9.0

# Wait for DB and WordPress to start up
sleep 30

# Install wp-cli
docker exec wordpress curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp

# Fetch Public IP
for i in {1..10}; do
  PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
  if [ ! -z "$PUBLIC_IP" ]; then
    break
  fi
  sleep 2
done
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP="127.0.0.1"
fi

# Run Core Install
docker exec --user www-data wordpress wp core install \
  --url="http://$PUBLIC_IP" \
  --title="CG Marketing Portal" \
  --admin_user=cgadmin \
  --admin_password=super-strong-wp-password \
  --admin_email=admin@cg.local

# Ensure upload directory exists and is writable
docker exec wordpress mkdir -p /var/www/html/wp-content/uploads
docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/uploads

# Create a sample post
docker exec --user www-data wordpress wp post create \
  --post_title="Welcome to our Marketing Site!" \
  --post_content="This is our official corporate marketing site. All uploads and updates are managed by the engineering team." \
  --post_status=publish
EOF

  tags = {
    Name = "cg-marketing-wp-${var.cgid}"
  }
}
