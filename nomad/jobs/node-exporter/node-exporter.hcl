job "node-exporter" {

  datacenters = ["us-west-2a"]
  type        = "system"

  group "node-exporter" {
    network {
      port "metrics" { static = 9100 }
    }
    task "node-exporter" {
      driver = "docker"
      config {
        image = "prom/node-exporter:v1.5.0"
        privileged = true
        ports = ["metrics"]
      }
      resources {
        cpu    = 200
        memory = 256
      }
      service {
        name = "node-exporter"
        port = "metrics"
        tags = [ "prometheus" ]
      }
    }
  }
}
