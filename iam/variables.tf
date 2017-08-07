variable "regions" {
   description = "Region for which the ECS policies will apply"
   type="list"
}

variable "num_regions" { 
    description = "Because of terraform limitations you must state how many regions you are passing in"
}

variable "service_name" { 
    description = "which ecs cluster are we targetting" 
}

