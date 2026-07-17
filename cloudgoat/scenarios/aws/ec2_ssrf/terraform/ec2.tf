resource "aws_iam_policy" "ec2_policy" {
  name        = "cg-ec2-role-policy-${var.cgid}"
  description = "Policy for the IAM role used by the EC2 instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name        = "cg-ec2-role-${var.cgid}"
  description = "IAM role used by the CloudGoat EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.ec2_policy.arn
  ]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "ec2_security_group" {
  name        = "cg-ec2-ssh-${var.cgid}"
  description = "CloudGoat ${var.cgid} Security Group for EC2 Instance over SSH"
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
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "cg-ec2-ssh-${var.cgid}"
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "cg-ec2-key-pair-${var.cgid}"
  public_key = file(var.ssh_public_key)
}

resource "aws_instance" "ubuntu_ec2" {
  ami                         = data.aws_ami.ec2.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]

  key_name = aws_key_pair.ec2_key_pair.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
        #!/bin/bash
        # Wait for any automatic apt/dpkg locks to release
        for i in {1..100}; do
          if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; then
            echo "Waiting for dpkg lock..."
            sleep 3
          else
            break
          fi
        done

        apt-get update
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        
        # Wait again before installing setup_20.x packages
        for i in {1..100}; do
          if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; then
            echo "Waiting for dpkg lock..."
            sleep 3
          else
            break
          fi
        done

        DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs

        mkdir -p /home/ubuntu/app
        cd /home/ubuntu/app

        # Write package.json using tee
        tee package.json <<'PACK'
{
  "name": "ssrf_app",
  "version": "1.0.0",
  "description": "NodeJS Web App with a SSRF vulnerability",
  "main": "app.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/sethsec/Nodejs-SSRF-App.git"
  },
  "author": "Seth Art",
  "license": "MIT",
  "bugs": {
    "url": "https://github.com/sethsec/Nodejs-SSRF-App/issues"
  },
  "homepage": "https://github.com/sethsec/Nodejs-SSRF-App#readme",
  "dependencies": {
    "express": "^4.19.2",
    "needle": "^3.3.1"
  }
}
PACK

        # Write app.js using tee
        tee app.js <<'APP'
//////////////////////////////////////////
// SSRF Demo App
// Node.js Application Vulnerable to SSRF
// Written by Seth Art <sethsec@gmail.com>
// MIT Licensed
//////////////////////////////////////////

var needle = require('needle');
var express = require('express');

// Currently this app is also vulnerable to reflective XSS as well. Kind of an easter egg :)

var app = express();
var port = 80

app.get('/', function (request, response) {
  var url = request.query['url'];
  if (request.query['mime'] == 'plain') {
    var mime = 'plain';
  } else {
    var mime = 'html';
  };

  console.log('New request: ' + request.url);

  // If the URL is not set, then we will just return the default page.
  if (url == undefined) {
    response.writeHead(200, { 'Content-Type': 'text/' + mime });
    response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
    response.write('<h2>I am an application. I want to be useful, so give me a URL to requested for you\n</h2><br><br>\n\n\n');
    response.end();
  } else { // If the URL is set, then we will try to request it.
    needle.get(url, { timeout: 3000 }, function (error, response1) {
      // If the request is successful, then we will return the response to the user.
      if (!error && response1.statusCode == 200) {
        response.writeHead(200, { 'Content-Type': 'text/' + mime });
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I am an application. I want to be useful, so I requested: <font color="red">' + url + '</font> for you\n</h2><br><br>\n\n\n');
        console.log(response1.body);
        response.write(response1.body);
        response.end();
      } else { // If the request is not successful, then we will return an error to the user.
        response.writeHead(404, { 'Content-Type': 'text/' + mime });
        response.write('<h1>Welcome to sethsec\'s SSRF demo.</h1>\n\n');
        response.write('<h2>I wanted to be useful, but I could not find: <font color="red">' + url + '</font> for you\n</h2><br><br>\n\n\n');
        response.end();
        console.log(error)
      }
    });
  }
})

app.listen(port);

console.log('\n##################################################')
console.log('#\n#  Server listening for connections on port:' + port);
console.log('#  Connect to server using the following url: \n#  -- http://[server]:' + port + '/?url=[SSRF URL]')
console.log('#\n##################################################')
APP

        npm install
        sudo node app.js &
        echo -e "\n* * * * * root node /home/ubuntu/app/app.js &\n* * * * * root sleep 10; node /home/ubuntu/app/app.js &\n* * * * * root sleep 20; node /home/ubuntu/app/app.js &\n* * * * * root sleep 30; node /home/ubuntu/app/app.js &\n* * * * * root sleep 40; node /home/ubuntu/app/app.js &\n* * * * * root sleep 50; node /home/ubuntu/app/app.js &\n" >> /etc/crontab
  EOF

  volume_tags = {
    Name = "CloudGoat ${var.cgid} EC2 Instance Root Device"
  }
  tags = {
    Name = "cg-ubuntu-ec2-${var.cgid}"
  }
}
