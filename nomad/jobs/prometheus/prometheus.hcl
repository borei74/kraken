job "prometheus" {
  datacenters = ["us-west-2a"]
  namespace = "default"

  constraint {
    attribute = "${node.class}"
    operator = "="
    value = "generic"
  }

  group "prometheus" {

    network {
      port "prometheus" {
        to = "9090"
      }
    }

    volume "prometheus-tsdb-vol" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      read_only       = false
      source          = "prometheus-tsdb-vol"
    }

    service {
      name = "prometheus"
      port = "prometheus"
      tags = ["http"]
    }

    task "prometheus" {
      driver = "docker"

      template {
        data = file("./templates/prometheus.yaml.tpl")
        destination = "alloc/prometheus.yaml"
      }
    
      volume_mount {
        volume = "prometheus-tsdb-vol"
        destination = "/var/lib/prometheus/tsdb"
        read_only = false
      }

      user = "root"
      config {
        image = "prom/prometheus:v2.41.0"
        args = [
          "--config.file=/etc/prometheus/prometheus.yaml",
          "--storage.tsdb.path=/var/lib/prometheus/tsdb",
          "--storage.tsdb.retention.time=1y",
          "--storage.tsdb.retention.size=64GB",
          "--log.level=debug"
        ]
        ports = ["prometheus"]
        volumes = [
          "alloc/prometheus.yaml:/etc/prometheus/prometheus.yaml"
        ]
      }

      resources {
        memory = 512
        cpu = 500
      }
    }
  }
}
