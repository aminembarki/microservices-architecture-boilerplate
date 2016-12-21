job "test" {
  datacenters = ["us-east-1"]
  type = "service"
  task "proxy" {
    driver = "docker"
    config {
      image = "tkellen/test"
      port_map {
        http = 80
      }
    }
    service {
      port = "http"
    }
    resources {
      network {
        mbits = 5
        port "http" {}
      }
    }
  }
}
