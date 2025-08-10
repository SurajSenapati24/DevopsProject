output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "frontend_url" {
  value = "http://${aws_instance.frontend.public_ip}:3000"
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}
