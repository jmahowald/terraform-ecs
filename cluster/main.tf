
data "aws_region" "current" {
  current = true
}
data "aws_caller_identity" "current" {}

variable "log_group_prefix" {
  description = "a naming convention used for log groups that the IAM profile uses to declare which logs it can write to. The terraform-env will be appended"
  default = "tf-ecs-group"
}
variable "autoscaling_group_name" { }
resource "aws_autoscaling_group" "app" {
  name_prefix          = "${var.autoscaling_group_name}"
  vpc_zone_identifier  = ["${var.asg_subnet_ids}"]
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.app.name}"
}

data "aws_ami" "ecs_ami" {
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
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}


data "template_file" "ecsconfig" {
  template = <<EOC
ECS_CLUSTER=${aws_ecs_cluster.main.name}
${var.ecs_extra_config}
EOC
}

resource "aws_launch_configuration" "app" {
  security_groups = [
    "${var.instance_security_group_id}",
  ]
  root_block_device {
    volume_size = "${var.volume_size}"
  }
  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.ecs_ami.id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.app.name}"
  user_data = <<EOC
#!/bin/bash
cat <<'EOP_SHELL'  > /etc/ecs/ecs.config
${data.template_file.ecsconfig.rendered}
EOP_SHELL
EOC

  lifecycle {
    create_before_destroy = true
  }
}

## ECS

resource "aws_ecs_cluster" "main" {
  name = "terraform-ecs-cluster-${terraform.env}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.main.id}"
}

## IAM

resource "aws_iam_instance_profile" "app" {
  name  = "tf-ecs-instprofile-${terraform.env}"
  roles = ["${aws_iam_role.app_instance.name}"]
}

resource "aws_iam_role" "app_instance" {
  name = "tf-instance-role-${terraform.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/instance-profile-policy.json")}"

  vars {
    arn_log_group_prefix= "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_prefix}-${terraform.env}/*"
  }
}


resource "aws_iam_role_policy" "instance" {
  name   = "ECS-Instance-${terraform.env}"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}


resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.log_group_prefix}-${terraform.env}/ecs-agent"
}

