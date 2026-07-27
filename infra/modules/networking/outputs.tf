output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet hosting the EC2 instance"
  value       = aws_subnet.public.id
}

output "server_security_group_id" {
  description = "ID of the security group for the Grafana/InfluxDB EC2 host"
  value       = aws_security_group.server.id
}
