tf_aws_centos_ami
=================

Terraform module to get the current set of approved windows amis

and then looks up the one you want given the input variables

## Input variables

  * version - (e.g. 2012)
  * region - E.g. eu-central-1
  * provider - e.g. aws, genesys

Outputs:

  * ami_id - the ami for the version and region
  * user_data_template_path - location to shipped template file for user data.  You'll need to supply the password variable into the template
  * winrm_port - genesys provider has 8888 for winrm port because of firewalls, whereas AWS marketplace has 5985

## Example use


    module "win_ami" {
      source = "http://rhodecode.genesyslab.com:5000/terraform-aws-lab.git/modules/windows"
      region = "eu-central-1"
      version = "7"
    }

    resource "template_file" "win_user_data" {
      filename = "${module.win_ami.user_data_template_path}"
      vars {
        password = "${var.windows_password}"
      }
    }


    resource "aws_instance" "atomic" {
      ami = "${module.win_ami.ami_id}"
      user_data = "${template_file.win_user_data.rendered}"
      connection {
        type = "winrm"
        user = "Administrator"
        port = "${module.windows.winrm_port}"
        password = "${var.windows_password}"
      }      ...
    }

## Stability note

The versioning scheme may change as we have multiple base images
I have no idea how I'll actually resolve this in future...

I recommend that you include this module by specific SHA for stability!

