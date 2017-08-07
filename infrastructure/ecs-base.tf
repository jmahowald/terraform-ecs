resource "aws_iam_role" "ecs_service" {
  name = "tf_ecs_role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

output "ecs_role_arn" {
  value = "${aws_iam_role.ecs_service.arn}"
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "tf_ecs_policy"
  role = "${aws_iam_role.ecs_service.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


variable "public_security_group_id" {}
variable "private_security_group_id" {}

variable "environment" {}


resource "aws_security_group_rule" "in_http" {
    source_security_group_id="${var.public_security_group_id}"
    security_group_id="${var.private_security_group_id}"
    from_port= 80
    to_port = 80
    type="ingress"
    protocol = "tcp"
}


resource "aws_security_group_rule" "in_docker_ephemeral" {
    source_security_group_id="${var.public_security_group_id}"
    security_group_id="${var.private_security_group_id}"
    from_port= 32768
    to_port = 60999
    type="ingress"
    protocol = "tcp"
}

resource "aws_security_group_rule" "out_docker_ephemeral" {
    security_group_id="${var.public_security_group_id}"
    source_security_group_id="${var.private_security_group_id}"
    from_port= 32768
    to_port = 60999
    type="egress"
    protocol = "tcp"
}

