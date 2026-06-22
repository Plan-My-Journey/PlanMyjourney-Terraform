output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for use with CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB for Route53 alias records"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the frontend target group for CloudWatch metrics"
  value       = aws_lb_target_group.frontend.arn_suffix
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener (redirects to HTTPS)"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (disabled until ACM cert is validated)"
  value       = aws_lb_listener.http.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "alb_logs_bucket" {
  description = "Name of the S3 bucket used for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}
