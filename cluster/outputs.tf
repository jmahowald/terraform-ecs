output "launch_configuration" {
  value = "${aws_launch_configuration.app.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.app.id}"
}


output "cloudwatch_log_group_prefix" {
  description = "all logs groups should start with the following"
  value = "${var.log_group_prefix}-${terraform.env}/"

}

output "ecs_role_arn" {
 value = "${var.ecs_role_arn}"
}

output "vpc_id" {
    value = "${data.aws_subnet.selected.vpc_id}"
}
