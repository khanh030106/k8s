output "ec2_public_ip" {
  value = aws_instance.k8s_server.public_ip
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_url" {
  description = "HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}