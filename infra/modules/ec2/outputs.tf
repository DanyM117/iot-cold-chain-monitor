output "instance_id" {
  description = "ID of the Grafana/InfluxDB EC2 instance"
  value       = aws_instance.server.id
}

output "public_ip" {
  description = "Public IP of the instance (Tailscale is the intended access path day-to-day)"
  value       = aws_instance.server.public_ip
}
