type        = "csi"
id          = "prometheus-tsdb-vol"
name        = "prometheus-tsdb-vol"
external_id = "vol-0d9e9d6faadb641ec"
plugin_id   = "aws-ebs0"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}
