terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  backend "s3" {
    bucket = "soleks-terraform-states"
    key = "states/nomad-kraken"
    region = "us-west-2"
    profile = "default"
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region = "us-west-2"
}

module "nomad-cluster" {
  source = "./modules/nomad-cluster"

  nomad-cluster-name = "nomad-kraken"
  consul-cluster-name = "consul-kraken"

  nomad-vpc = {
    name = "nomad-kraken-vpc"
    cidr_block = "172.16.0.0/22"
    region = "us-west-2"
    availability_zones = ["a"]
  }

  nomad-server = {
    prefix = "nomad-server"
    ami_name = "nomad-base-image-ver-0.1"
    instance_type = "t3.micro"
    min_size = 3
    max_size = 3
  }

  nomad-client = {
    prefix = "nomad-client"
    ami_name = "nomad-base-image-ver-0.1"
    instance_type = "t3.medium"
    min_size = 2
    max_size = 2
  }

  nomad-edge = {
    prefix = "nomad-edge"
    ami_name = "nomad-base-image-ver-0.1"
    instance_type = "t3.micro"
    pool_size = 2
    client = true
    workload = false
  }

  consul-server = {
    prefix = "consul-server"
    ami_name = "consul-base-image-ver-0.1"
    instance_type = "t3.small"
    min_size = 3
    max_size = 3
  }

  nomad-bootstrap = {
    prefix = "nomad-bootstrap"
    ami_name = "nomad-base-image-ver-0.1"
    instance_type = "t3.small"
  }

  nomad-dns-zone = "soleks.net"
}
