job "grafana" {
  datacenters = ["us-west-2a"]
  namespace = "default"

  constraint {
    attribute = "${node.class}"
    operator = "="
    value = "generic"
  }

  group "grafana" {

    network {
      mode = "bridge"
      port "grafana" {
        to = "3000"
      }
    }

    volume "grafana-vol" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      read_only       = false
      source          = "grafana-vol"
    }

    service {
      name = "grafana"
      port = "grafana"
      tags = ["http"]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "mysql"
              local_bind_port  = 3306
            }
          }
        }
      }
    }

    task "grafana" {
      driver = "docker"

      template {
        data = file("./templates/grafana.ini")
        destination = "alloc/grafana.ini"
      }
    
      volume_mount {
        volume = "grafana-vol"
        destination = "/var/lib/grafana-vol"
        read_only = false
      }

      config {
        image = "grafana/grafana-oss:9.2.2-ubuntu"
#        image = "ubuntu/22.04"
#        command = "sleep"
#        args = ["86400"]
        ports = ["grafana"]
        volumes = [
          "alloc/grafana.ini:/etc/grafana/grafana.ini"
        ]
      }

      resources {
        memory = 512
        cpu = 500
      }
    }
  }
}
