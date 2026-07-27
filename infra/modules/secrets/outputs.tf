output "parameter_arns" {
  description = "ARNs of the created SSM parameters"
  value = {
    influx_url     = aws_ssm_parameter.influx_url.arn
    influx_token   = aws_ssm_parameter.influx_token.arn
    influx_org     = aws_ssm_parameter.influx_org.arn
    influx_bucket  = aws_ssm_parameter.influx_bucket.arn
    email_from     = aws_ssm_parameter.email_from.arn
    email_password = aws_ssm_parameter.email_password.arn
    email_to       = aws_ssm_parameter.email_to.arn
  }
}
