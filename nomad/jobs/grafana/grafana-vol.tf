resource "aws_ebs_volume" "grafana-vol" {
  availability_zone = "us-west-2a"
  size              = 64
  type              = "gp2"
  tags = {
    Name="grafana-vol"
  }
}

output "grafana-vol" {
    value = <<EOM
# volume registration
type        = "csi"
id          = "grafana-vol"
name        = "grafana-vol"
external_id = "${aws_ebs_volume.grafana-vol.id}"
plugin_id   = "aws-ebs0"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
EOM
}
