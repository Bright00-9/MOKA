output "alb_dns_name" {
  description = "Point PLATFORM_CALLBACK_URL and the Flutter apps' API_BASE_URL at this"
  value       = aws_lb.backend.dns_name
}
