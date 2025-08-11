job "plugin-aws-ebs-controller" {
  datacenters = ["us-west-2a"]

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "registry.k8s.io/provider-aws/aws-ebs-csi-driver:v1.15.0"

        args = [
          "controller",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]
      }

      csi_plugin {
        id        = "aws-ebs0"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}

