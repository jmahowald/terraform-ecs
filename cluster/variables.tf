

variable "asg_subnet_ids" { 
  type = "list"
}

variable "elb_subnet_ids" {
  type = "list"
}

variable "volume_size" {
  default = 30
}
variable "instance_security_group_id" {
}
variable "key_name" {
  description = "Name of AWS key pair"
}

variable "ecs_config_entries" {
  default = {}
  description = "Map of key value pairs to add into the config"
}
variable "ecs_extra_config" {
  description = "other settings you want. See [ECS Agent Config](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html)"
}
variable "environment_name" {}

variable "ecs_role_arn" {
  description = "Role to pass on to services to use ECS"
}

variable "instance_type" {
  default     = "t2.small"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "2"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "1"
}

// variable "admin_cidr_ingress" {
//   description = "limit access to ECS instances to these CIDRs"
//   default = "0.0.0.0/0"
// }

variable "virtualization_type" {
   description = "type of virtualization for ecs instnaces"
   default =   "hvm"
}