terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
  ## profile = "my-profile"
}


resource "aws_security_group" "roman_numerals_sec_grp" {
  name        = "roman_numerals_sec_grp"
  description = "roman_numerals_sec_grp"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "roman_instance" {
  ami           = "ami-005f9685cb30f234b"
  security_groups = [ "roman_numerals_sec_grp" ]
  key_name = "first-key"
  instance_type = "t2.micro"
  user_data = <<EOF
        #!/bin/bash 
        yum update -y
        yum install python3 -y
        pip3 install flask
        cd /home/ec2-user
        wget https://raw.githubusercontent.com/mesutal/Amazon-Web-Services-Projects/main/Projects/Project-001-Roman-Numerals-Converter/app.py
        mkdir templates
        cd templates
        wget https://raw.githubusercontent.com/mesutal/Amazon-Web-Services-Projects/main/Projects/Project-001-Roman-Numerals-Converter/templates/index.html
        wget https://raw.githubusercontent.com/mesutal/Amazon-Web-Services-Projects/main/Projects/Project-001-Roman-Numerals-Converter/templates/result.html
        cd ..
        python3 app.py
  EOF
  tags = {
    name = "Terraformproject"

  }
}