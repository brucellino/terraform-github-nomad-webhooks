job "cloudflared" {
  datacenters = ["dc1"]
  type        = "service"

  group "nomad" {
    reschedule {
      attempts       = 1
      interval       = "1m"
      unlimited      = false
      delay_function = "constant"
    }

    restart {
      attempts = 1
      interval = "2m"
      delay    = "15s"
      mode     = "delay"
    }

    network {
      port "metrics"{}
      port "cloudflared"{}

      mode = "bridge"
    }

    task "tunnel" {
      service {
        name = "cloudflared-nomad"
        tags = ["cloudflared", "nomad"]
        port = "cloudflared"

        check {
          name     = "metrics"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          port     = "metrics"
          path = "/"
        }

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      restart {
        interval = "1m"
        attempts = 1
        delay    = "5s"
        mode     = "fail"
      }

      driver = "docker"

      config {
        image = "cloudflare/cloudflared"
        ports = ["metrics"]
        args = [
          "tunnel",
          "--autoupdate-freq",
          "24h",
          "--loglevel",
          "info",
          "--metrics",
          "localhost:$${NOMAD_PORT_metrics}",
          "run",
          "--token",
          "${token}",
        ]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
