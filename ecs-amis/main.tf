




variable "channel" {
  default = "stable"
}

variable "virtualization_type" {
  default = "hvm"
}


data "aws_ami" "amazon" {
  most_recent = true
   filter {
    name = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["${var.virtualization_type}"]
  }
  filter {
    name   = "name"
    values = ["amzn-ami-*ecs*"]
  }
}

output "ami_id" {
  value = "${data.aws_ami.amazon.image_id}"
}

output "image_user" {
  value = "ec2-user"
}

variable "version" {
    default = "7"
}
