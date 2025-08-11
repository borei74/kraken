job "mysql" {
  datacenters = ["us-west-2a"]
  namespace = "default"

  group "mysql" {

    network {
      mode = "bridge"
    }

    volume "mysql-vol" {
      type      = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      read_only = false
      source    = "mysql-vol"
    }

    service {
      name = "mysql"
      port = "3306"
      tags = ["mysql"]
      connect {
        sidecar_service {}
      }
    }

    task "mysql" {
      driver = "docker"

      volume_mount {
        volume = "mysql-vol"
        destination = "/var/lib/mysql"
        read_only = false
      }

      config {
        image = "mariadb:10.10.2"
        # ports = ["mysql"]
      }

      template {
        data = <<EOH
        MARIADB_ROOT_PASSWORD = "ahgovaeDeog4"
        MARIADB_DATABASE = "grafana"
        MARIADB_USER = "grafana"
        MARIADB_PASSWORD = "bohghah7Eex4"
        EOH

        destination = "secrets/mysql.env"
        env = true
      }

      resources {
        memory = 1024
        cpu = 1000
      }
    }
  }
}
