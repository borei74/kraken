// nomad-cluster variables declarations and default values
//

variable "nomad-cluster-name" {
  type = string
  default = "nomad"
}

variable "consul-cluster-name" {
  type = string
  default = "consul"
}

variable "nomad-server" {
  type = object({
    prefix = string
    ami_name = string
    instance_type = string
    min_size = number
    max_size = number
  })
  default = {
    prefix = "nomad-server"
    ami_name = "nomad-base-img"
    instance_type = "t2.micro"
    min_size = 1
    max_size = 1
  }
}

variable "nomad-client" {
  type = object({
    prefix = string
    ami_name = string
    instance_type = string
    min_size = number
    max_size = number
  })
  default = {
    prefix = "nomad-client"
    ami_name = "nomad-base-img"
    instance_type = "t2.micro"
    min_size = 1
    max_size = 1
  }
}

# Pool of the edge VMs for nomad cluster, representing AWS auto-scaling group.
# Behaviour and configuration of the edge VM are controlled by the following options:
# 'client': 'true' - node is a member of the nomad cluster, acting as client agent.
# 'workload': 'true' - node can take user defined workload. if 'client' is 'false' then 'workload' will be ignored, defaulting to 'false'.
# Main purpose of 'nomad-edge' pool is to run edge proxy.
#
variable "nomad-edge" {
  type = object({
    prefix = string
    ami_name = string
    instance_type = string
    pool_size = number
    workload = bool
    client = bool
  })
  default = {
    prefix = "nomad-edge"
    ami_name = "nomad-base-img"
    instance_type = "t2.micro"
    pool_size = 1
    workload = false
    client = true
  }
}

variable "consul-server" {
  type = object({
    prefix = string
    ami_name = string
    instance_type = string
    min_size = number
    max_size = number
  })
  default = {
    prefix = "consul-server"
    ami_name = "consul-base-img"
    instance_type = "t2.micro"
    min_size = 1
    max_size = 1
  }
}

variable "nomad-bootstrap" {
  type = object({
    prefix = string
    ami_name = string
    instance_type = string
  })
  default = {
    prefix = "nomad-bootstrap"
    ami_name = "nomad-base-img"
    instance_type = "t2.micro"
  }
}

variable "nomad-vpc" {
  type = object({
    name = string
    cidr_block = string
    region = string
    availability_zones = list(string)
  })
  default = {
    name = "nomad-vpc"
    cidr_block = "0.0.0.0/0"
    region = "us-west-2"
    availability_zones = ["a"]
  }
}

variable "nomad-dns-zone" {
  type = string
  default = "localdomain"
}
