output "ssh" {
  description = "Public IP of instance (or EIP)"
  value       = "ssh -i ec2_cloudwatch_private_key.pem ec2-user@${aws_instance.ec2.public_ip}"
}

output "vpc" {
  description = "Default VPC Id"
  value       = "${data.aws_vpc.default.id}"
}
