output "alb_dns_name" {
  description = "Public DNS of the ALB"
  value       = aws_lb.backend.dns_name
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}