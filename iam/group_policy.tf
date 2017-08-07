
data "aws_caller_identity" "current" {}

data "template_file" "cluster_management_options" {
   vars {
       service_name = "${var.service_name}"
       region = "${element(var.regions, count.index)}"
       account_id = "${data.aws_caller_identity.current.account_id}"
   }
   count = "${var.num_regions}"
   template = "${file("${path.module}/group.policy.tpl.json")}"
}



resource "aws_iam_policy" "ecs_operations" {
    name = "ecs-operations-${var.service_name}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:Describe*",
        "ecs:List*",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm",
        "elasticloadbalancing:Describe*",
        "iam:GetRole",
        "iam:ListRoles",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:CreateService",
        "ecs:UpdateService",
        "cloudformation:DescribeStack*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    ${join(",",data.template_file.cluster_management_options.*.rendered)}
  ]
}
EOF
}

//TODO - this is for dev purposes and doesn't need to be in "production"
output "policy_sections" {
    value =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:Describe*",
        "ecs:List*",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm",
        "elasticloadbalancing:Describe*",
        "iam:GetRole",
        "iam:ListRoles",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:CreateService",
        "ecs:UpdateService",
        "cloudformation:DescribeStack*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    ${join(",",data.template_file.cluster_management_options.*.rendered)}
  ]
}    
EOF
}

