# Define the provider for AWS
provider "aws" {
  region = "us-east-1"
}

# Create a new security group for the app
resource "aws_security_group" "flask_app_sg" {
  name_prefix = "flask_app_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new EC2 instance to run the app
resource "aws_instance" "flask_app" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name      = "my_key_pair"
  security_groups = [
    aws_security_group.flask_app_sg.id,
  ]

  # Use user_data to install Python and Flask, and start the app
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y python3-pip
              sudo pip3 install flask
              sudo echo '
              import os
              from flask import Flask, send_from_directory
              
              app = Flask(__name__)

              @app.route("/")
              def index():
                  return "Hello, World!"

              @app.route("/greet/<name>")
              def greet(name):
                  return f"Hello, {name}!"

              @app.route("/static/<path:path>")
              def serve_static(path):
                  root_dir = os.getcwd()
                  return send_from_directory(os.path.join(root_dir, "static"), path)

              if __name__ == "__main__":
                  app.run(host="0.0.0.0")
              ' > /home/ec2-user/app.py
              sudo chmod +x /home/ec2-user/app.py
              sudo nohup python3 /home/ec2-user/app.py > /dev/null 2>&1 &
              EOF

  tags = {
    Name = "flask-app-instance"
  }
}

# Output the public IP address of the instance
output "public_ip" {
  value = aws_instance.flask_app.public_ip
}
