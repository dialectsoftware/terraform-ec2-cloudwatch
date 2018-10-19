#https://www.terraform.io/docs/providers/aws/r/instance.html
#https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html
#https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html
#https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/EC2NewInstanceCWL.html
#https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/troubleshooting-CloudWatch-Agent.html
#https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AgentReference.html
#https://medium.com/@kulasangar91/creating-and-attaching-an-aws-iam-role-with-a-policy-to-an-ec2-instance-using-terraform-scripts-aa85f3e6dfff

terraform {
    required_version = "> 0.7.0"
}

provider "aws"{
    version = "~>1.15"
    region = "${var.aws_region}"
}

resource "tls_private_key" "ec2_cloudwatch_key"{
    algorithm = "RSA"
    rsa_bits = "4096"
}

resource "aws_key_pair" "ec2_cloudwatch_key_pair"{
    key_name = "${var.key_name}"
    public_key = "${tls_private_key.ec2_cloudwatch_key.public_key_openssh}"
}

resource "local_file" "private_key_pem" {
  content  = "${tls_private_key.ec2_cloudwatch_key.private_key_pem}"
  filename = "${var.key_name}.pem"
}

resource "aws_security_group" "ec2_cloudwatch_security_group" {
  name = "sg_aws_ec2_cloudwatch"

  tags {
    Name = "SSH/HTTP"
  }

  description = "ALLOW ONLY SSH & HTTP CONNECTION INBOUND"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "cloud_init" {
  template = "${file("cloud-init.tpl")}"

  vars {
    log_name = "${var.log_name}"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "ec2_cloudwatch_policy"
  description = "EC2 CloudWatch Agent Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "role" {
  lifecycle {
    ignore_changes = ["*"]
  }

  name  = "EC2CloudWatchAccessRole"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach-policy" {
  name       = "EC2CloudWatchAccessRoleAttachment"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "profile" {
  name  = "EC2CloudwatchInstanceProfile"
  role = "${aws_iam_role.role.name}"
}

data "aws_vpc" "default" {
  default = true
}

#TODO: Add S3 VCP Endpoint
#resource "aws_vpc_endpoint" "s3" {
#  vpc_id       = "${aws_default_vpc.default.id}"
#  service_name = "com.amazonaws.${var.aws_region}.s3"
#}

resource "aws_instance" "ec2" {
  ami               = "${var.aws_ami["${var.aws_region}"]}" 
  availability_zone = "${var.aws_region}a"
  instance_type     = "t1.micro"
  key_name               = "${aws_key_pair.ec2_cloudwatch_key_pair.id}"
  vpc_security_group_ids = ["${aws_security_group.ec2_cloudwatch_security_group.id}"]
  user_data              = "${data.template_file.cloud_init.rendered}"
  iam_instance_profile   = "${aws_iam_instance_profile.profile.name}"

  tags {
    Name = "EC2CloudWatchLogs"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }
}