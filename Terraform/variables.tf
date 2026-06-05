variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu AMI"
}

variable "key_name" {
  description = "EC2 key pair name"
}