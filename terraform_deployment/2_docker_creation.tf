# Rudimentary ECR/Docker Creation
##################################################################
########### ECR Creation ###########
resource "aws_ecr_repository" "airflow_webserver" {
  name                 = "airflow-ws"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "airflow-ws"
    }
  )
}
resource "aws_ecr_repository" "airflow_scheduler" {
  name                 = "airflow-sc"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "airflow-sc"
    }
  )
}
resource "aws_ecr_repository" "airflow_worker" {
  name                 = "airflow-wk"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "airflow-wk"
    }
  )
}
##################################################################
########### EC2 IAM Role and Policies ###########
### Role Creation
resource "aws_iam_role" "docker_ec2_role" {
  name = "docker_ec2_role"
  assume_role_policy = file("./docker/ec2_iam_assume.json")
}
### EC2 Instance Profile
resource "aws_iam_instance_profile" "test_profile" {
  name = "docker_ec2_role"
  role = aws_iam_role.docker_ec2_role.name
}
### Policy Attachment
resource "aws_iam_role_policy_attachment" "docker_ec2_ecr" {
  role       = aws_iam_role.docker_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
##################################################################
########### EC2 Creation ###########
### Security Group
resource "aws_security_group" "docker_ob" {
  name        = "docker_outbound"
  description = "Docker EC2 outbound traffic"
  vpc_id      = module.main_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "docker_outbound"
    }
  )

}
### Security Group
resource "aws_instance" "docker" {
  ami           = var.tmp_ec2_attrs.ami
  instance_type = var.tmp_ec2_attrs.instance_type

  associate_public_ip_address = true

  user_data = templatefile("./docker/docker_setup.tpl",
        { 
            region     = var.tf_creds.region,
            ecr_ws_url = aws_ecr_repository.airflow_webserver.repository_url
            ecr_sc_url = aws_ecr_repository.airflow_scheduler.repository_url
            ecr_wk_url = aws_ecr_repository.airflow_worker.repository_url
        }  
  )

  subnet_id = module.main_vpc.public_sn[0].id

  iam_instance_profile = aws_iam_instance_profile.test_profile.id
  
  vpc_security_group_ids = [
      aws_security_group.docker_ob.id
  ]

  root_block_device {
    volume_size           = 32
    volume_type           = "gp3"
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "docker-ec2-tmp"
    }
  )

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}
