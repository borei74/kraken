job "web-service" {
  datacenters = ["us-west-2a"]

  constraint {
    attribute = "${node.class}"
    operator = "="
    value = "generic"
  }

  group "web-service" {

    count = 2
   
    network {
      mode = "bridge"
      port "web-service" {
        to = "8080"
      }
    }

    service {
      name = "web-service"
      port = "web-service"
      tags = [
        "envoy.enable=true",
        "envoy.http.enabled=true",
        "envoy.http.vhost=web-service.soleks.net",
        "envoy.http.domain=web-service.soleks.net",
        "envoy.http.tls=true",
        "envoy.http.tls.sni=soleks.net",
      ] 
      check {
        name = "web-service-check"
        type = "http"
        path = "/"
        interval = "10s"
        timeout = "1s"
      }
    }

    task "web-service" {
      driver = "docker"

      env {
        ALLOC_ID = "${NOMAD_ALLOC_ID}"
      }

      config {
        image = "web-service:v0.1"
        ports = ["web-service"]
      }

      resources {
        memory = 128
        cpu = 100
      }
    }
  }
}
