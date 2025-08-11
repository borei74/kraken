resource "aws_ebs_volume" "mysql-vol" {
  availability_zone = "us-west-2a"
  size              = 64
  type              = "gp2"
  tags = {
    Name="mysql-vol"
  }
}

output "mysql-vol" {
    value = <<EOM
# volume registration
type        = "csi"
id          = "mysql-vol"
name        = "mysql-vol"
external_id = "${aws_ebs_volume.mysql-vol.id}"
plugin_id   = "aws-ebs0"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
EOM
}
