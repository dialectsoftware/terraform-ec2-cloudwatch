variable aws_region{
    type = "string"
    default = "us-east-1"
}

variable key_name{
    type="string"
    default="ec2_cloudwatch_private_key"
}

variable "aws_ami" {
  type="map"
  default = {
    us-east-1 = "ami-0922553b7b0369273"
    us-west-2 = "ami-0d1000aff9a9bad89"
  }
}

variable "log_name" {
    type="string"
    default="loggy"
}


