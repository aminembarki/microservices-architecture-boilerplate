job "proxy" {
  datacenters = ["us-east-1"]
  type = "service"
  task "test" {
    driver = "docker"
    config {
      image = "tkellen/test"
      port_map {
        http = 80
      }
    }
    service {
      name = "goingslowly-proxy"
      port = "http"
      tags = ["urlprefix-gs.loc/"]
      check = {
        type = "http"
        name = "health"
        path = "/"
        interval = "5s"
        timeout = "2s"
      }
    }
    resources {
      network {
        mbits = 5
        port "http" {}
      }
    }
  }
}
