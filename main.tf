#########################################################
# S3 Backend
#########################################################

terraform {
  backend "s3" {
   }
}


data "aws_caller_identity" "current" {}

#########################################################
# Network Module
#########################################################

module "networking" {
  source                = "./modules/network/"
  region                = "${var.region}"
  environment           = "${var.environment}"
  vpc_cidr              = "${var.vpc_cidr}"
  public_subnets_cidr   = "${var.public_subnets_cidr}"
  private_subnets_cidr  = "${var.private_subnets_cidr}"
  availability_zones    = "${var.availability_zones}"
}

#########################################################
# EC2 Modulle
#########################################################

module "ec2" {
  source                 = "./modules/ec2/"
  environment            = "${var.environment}"
  vpc_id                 = module.networking.vpc_id
  key_name               = "${var.key_name}"
  private_subnet_id      = module.networking.private_subnet_id
  public_subnet_id       = module.networking.public_subnet_id
  private_ips            = "${var.private_ips}"
  vpc_cidr               = "${var.vpc_cidr}"
  instance_type          = "${var.instance_type}"
}

#########################################################
# Ansible Resources
#########################################################

resource "ansible_host" "es" {
  count                 = length(var.private_ips)
  inventory_hostname    = module.ec2.es_public_ip[count.index]
# groups                = ["es${count.index + 1}"]
  groups                = ["es"]
  vars = {
    ansible_user        = "ec2-user"
    become              = "yes"
    interpreter_python  = "/usr/bin/python2"
  }
}
