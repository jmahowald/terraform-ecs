
variable "vpc_id" { }
variable "listener_arn" {}
variable "cluster_id" {}
variable "ecs_role_arn" {}
variable "log_group_prefix" {}
variable "retention_in_days" {
  default = 30
}

variable "task_def_container_defs" {
  description = "JSON array of container defintions"
}

variable "lb_container_name" {
    description = "The name of the container in your task defintion that will be hit by the load balancer"
}
variable "container_port" { }
variable "desired_count" {
    default = 2
}
variable "service_name" {
    description = "Name of the ECS service"
}
variable "hostnamerule" {
    description = "what is the pattern to match for"
}
variable "priority" {
    description = "the priority amongst all the rules of the listener (unfortunately must be unique)"
}

variable "health_check" {
  description = "health check parameters for the ALB. See https://www.terraform.io/docs/providers/aws/r/alb_target_group.html#interval"
  default = []
}

resource "aws_alb_target_group" "default" {
  name = "${terraform.env}-${var.service_name}"
  //This shouldn't be required since we'll be using dynamic port mapping 
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  health_check = "${var.health_check}"
}

resource "aws_alb_listener_rule" "host_based_routing" {
  listener_arn = "${var.listener_arn}"
  priority     = "${var.priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.default.arn}"
  }
  condition {
    field  = "host-header"
    values = ["${var.hostnamerule}"]
  }
}

resource "aws_ecs_service" "default" {
  name            = "${var.lb_container_name}"
  cluster         = "${var.cluster_id}"

  task_definition = "${aws_ecs_task_definition.default.arn}"
  desired_count   = "${var.desired_count}"
  iam_role        = "${var.ecs_role_arn}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.default.arn}" 
    container_name = "${var.lb_container_name}"
    container_port = "${var.container_port}"
  }

  # Track the latest ACTIVE revision
  // task_definition = "${aws_ecs_task_definition.default.family}:${max("${aws_ecs_task_definition.default.revision}", "${data.aws_ecs_task_definition.default.revision}")}"

}

resource "aws_ecs_task_definition" "default" {
  family = "${var.service_name}"
  container_definitions = "${var.task_def_container_defs}"
}


resource "aws_cloudwatch_log_group" "default" {
  name = "${var.log_group_prefix}${var.service_name}"
  retention_in_days  = "${var.retention_in_days}"
}