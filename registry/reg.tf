/**
 * To be used in conjunction with ECS.  This simply renders the correct config for ECS to use a private repo.
 * In realitiy this should dissapear/store the info in s3 . . 
 */

variable "registry_address" { }
variable "registry_password" { }
variable "registry_account" { }

data "template_file" "ecs_reg_config" {
    template = <<EOC
ECS_ENGINE_AUTH_TYPE=docker
ECS_ENGINE_AUTH_DATA={"https://$${registry_address}":{"username":"$${registry_account}","password":"$${registry_password}"}}
EOC
    vars {
        registry_address = "${var.registry_address}"
        registry_password = "${var.registry_password}"
        registry_account = "${var.registry_account}"

    }
}

output "ecs_auth_data" { 
    value = "${data.template_file.ecs_reg_config.rendered}"
}