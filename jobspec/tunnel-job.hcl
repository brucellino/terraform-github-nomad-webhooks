job "cloudflared" {
  datacenters = ["dc1"]
  type        = "service"
  update {
    max_parallel      = 3
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = true
    auto_promote      = true
    canary            = 1
    stagger           = "30s"
  }
  group "nomad" {
    count =2
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

      // mode = "bridge"
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
          path = "/metrics"
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
          "0.0.0.0:$${NOMAD_PORT_metrics}",
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
