job "dispatch" {
  datacenters = ["dc1"]
  type = "batch"
  parameterized {
    payload = "required"

  }
  group "payload" {
    task "test" {
      dispatch_payload {
        file = "payload.json"
      }
      driver = "raw_exec"
      config {
        command = "/bin/cat"
        args = ["$${NOMAD_TASK_DIR}/payload.json"]
      }
      identity {
        env  = true
        file = true
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
