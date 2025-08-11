type        = "csi"
id          = "grafana-vol"
name        = "grafana-vol"
external_id = "vol-000178b0572ba8534"
plugin_id   = "aws-ebs0"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
