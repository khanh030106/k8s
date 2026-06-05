terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_security_group.k8s_sg.vpc_id]
  }
}

resource "aws_security_group" "k8s_sg" {
  name = "k8s-security-group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort from Internet"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort from same SG"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_server" {
  ami           = var.ami_id
  instance_type = "t2.medium"

  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.k8s_sg.id
  ]

  associate_public_ip_address = true

  user_data = file("user_data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-terraform-server"
  }
}

resource "aws_lb" "app_alb" {
  name               = "k8s-app-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [
    aws_security_group.k8s_sg.id
  ]

  subnets = [
    "subnet-00a76448ec002b595",
    "subnet-08f4ba2dc4626783c",
    "subnet-0b6db64b68c436be4"
  ]

  tags = {
    Name = "k8s-app-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "k8s-app-tg"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = aws_security_group.k8s_sg.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "30080"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.k8s_server.id
  port             = 30080
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}