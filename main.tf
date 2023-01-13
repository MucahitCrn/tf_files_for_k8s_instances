terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "aws_access" {
  name = "awsrole-${var.user}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "romeo-project-profile-${var.user}"
  role = aws_iam_role.aws_access.name
}

# FOR MASTER NODE INSTANCE
resource "aws_instance" "master_node" {
  ami = var.myami
  instance_type = var.masterinstancetype
  key_name      = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-k8s-master-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  tags = {
    Name = "romeo_control"
    stack = "romeo_project"
  }
  user_data = file("master.sh")
}

# FOR WORKER NODE INSTANCES
resource "aws_instance" "worker_nodes" {
  ami = var.myami
  instance_type = var.workerinstancetype
  count = var.num
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-k8s-master-sec-gr.id]
  tags = {
    Name = "romeo_${element(var.tags, count.index )}"
    stack = "romeo_project"
    environment = "development"
  }
  user_data = file("worker_node.sh")
}

# FOR SSH CONNECTION. KEY PEM FILE IN THE (MYVARS.AUTO.TFVARS) FOLDER
resource "null_resource" "config" {
  depends_on = [aws_instance.master_node]
  connection {
    host = aws_instance.control_node.public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/${var.mykey}.pem")
    # Do not forget to define your key file path correctly!
  }
}

# SEC GROUP
resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}



 output "master_public_dns" {
   value = aws_instance.master_node.public_dns
}

 output "master_private_dns" {
   value = aws_instance.master_node.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker_1.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker_1.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker_2.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker_2.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker_3.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker_3.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker_4.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker_4.private_dns
}
