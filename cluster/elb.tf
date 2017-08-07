
data "aws_subnet" "selected" {
  id = "${element(var.public_subnet_ids,0)}"
}

variable "public_security_group_id" {}
variable "private_security_group_id" {}

variable "environment" {}

variable "public_subnet_ids" {
    type = "list"
}
variable "private_subnet_ids" {
    type = "list"
}
variable "tags" {
    default = {}
}
data "aws_vpc" "vpc" {
    id = "${data.aws_subnet.selected.vpc_id}"
}



data "aws_acm_certificate" "public_wildcard" {
    domain = "*.${var.zone_name}"
    statuses = ["ISSUED"]
}
resource "aws_alb" "public" {
  name            = "public-${var.environment}"
  internal        = false
  security_groups = ["${var.public_security_group_id}"]
  subnets         = ["${var.public_subnet_ids}"]

  enable_deletion_protection = true
  access_logs {
    bucket = "${aws_s3_bucket.elb_logs.bucket}"
    prefix = "public-${data.aws_region.current.name}"
  }
  tags = "${merge(map("Name","public-alb"),var.tags)}"
}



resource "aws_alb_listener" "public_wildcard" {
   load_balancer_arn = "${aws_alb.public.arn}"
   port = "443"
   protocol = "HTTPS"
   ssl_policy = "ELBSecurityPolicy-2015-05"
   certificate_arn = "${data.aws_acm_certificate.public_wildcard.arn}"
   default_action {
     target_group_arn = "${aws_alb_target_group.default.arn}"
     type = "forward"
   }
}


// TODO remove the name traefik, but it requires us to tear down a bunch more
resource "aws_alb_target_group" "default" {
  name     = "default-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_subnet.selected.vpc_id}"
  health_check {
    path = "/index.html"
    matcher = "200"
  }
}


output "public_listener_arn" {
    value = "${aws_alb_listener.public_wildcard.arn}"
}
output "default_target_group_arn" {
    value="${aws_alb_target_group.default.arn}"
}

data "aws_iam_policy_document" "elb_logs" {
    statement {
        actions = [
            "s3:PutObject",
        ]
        resources = [
            "arn:aws:s3:::${aws_s3_bucket.elb_logs.bucket}/public-${data.aws_region.current.name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        ]
        principals {
            type = "AWS"
            identifiers = [ "${data.aws_elb_service_account.main.arn}"]
        }
    }

}

data "aws_elb_service_account" "main" { }


resource "aws_s3_bucket" "elb_logs" {
    bucket = "elb.logs.${var.zone_name}"
    acl = "private"
}


resource "aws_s3_bucket_policy" "elb_logs" {
  bucket = "${aws_s3_bucket.elb_logs.bucket}"
  policy = "${data.aws_iam_policy_document.elb_logs.json}"
}

variable "zone_name" {}
data "aws_route53_zone" "selected" {
    name="${var.zone_name}"
}
resource "aws_route53_record" "public_wildcard" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name = "*.${data.aws_route53_zone.selected.name}"
  type = "A"
  alias {
    name = "${aws_alb.public.dns_name}"
    zone_id = "${aws_alb.public.zone_id}"
    evaluate_target_health= true
  }
}
