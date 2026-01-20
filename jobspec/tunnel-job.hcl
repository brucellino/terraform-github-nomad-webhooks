job "cloudflared-${github_user}" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "$${attr.cpu.arch}"
    value = "arm64"
  }
  update {
    max_parallel      = 2
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
    count = 1
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
        name = "cloudflared-nomad-${github_user}"
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

      driver = "raw_exec"

      template {
        change_mode = "noop"
        data =<<EOT
#!/bin/bash
echo "starting cloudflared"

ls -lht {{ env "NOMAD_TASK_DIR "}}
chmod -v u+x {{ env "NOMAD_TASK_DIR" }}/cloudflared
{{ env "NOMAD_TASK_DIR" }}/cloudflared \
  tunnel \
  --autoupdate-freq 24h \
  --loglevel info \
  --metrics 0.0.0.0:{{ env "NOMAD_PORT_metrics" }} \
  run --token ${token}
        EOT
        destination = "$${NOMAD_TASK_DIR}/start.sh"
        perms = "0777"
      }

      artifact {
        source = "https://github.com/cloudflare/cloudflared/releases/download/2024.10.1/cloudflared-linux-$${attr.cpu.arch}"
        destination = "$${NOMAD_TASK_DIR}/cloudflared"
        options {
          checksum = "sha256:80b2014200be8851886d441cf5df54652e014444105eebc43f15081d1e2af6a8"
        }
        mode = "file"
      }
      config {
        command = "$${NOMAD_TASK_DIR}/start.sh"
      }

      resources {
        cpu    = 125
        memory = 256
      }
    }
  }
}
