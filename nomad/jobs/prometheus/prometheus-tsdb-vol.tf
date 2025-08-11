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
    key = "states/prometheus-kraken"
    region = "us-west-2"
    profile = "default"
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region = "us-west-2"
}

resource "aws_ebs_volume" "prometheus-tsdb-vol" {
  availability_zone = "us-west-2a"
  size              = 64
  type              = "gp2"
  tags = {
    Name="prometheus-tsdb-vol"
  }
}

output "ebs_volume" {
    value = <<EOM
# volume registration
type        = "csi"
id          = "prometheus-tsdb-vol"
name        = "prometheus-tsdb-vol"
external_id = "${aws_ebs_volume.prometheus-tsdb-vol.id}"
plugin_id   = "aws-ebs0"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
EOM
}
