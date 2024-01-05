export default {
  async fetch(request, env) {
    /**
     * rawHtmlResponse returns HTML inputted directly
     * into the worker script
     * @param {string} html
     */
    // let nomad_endpoint = await env.WORKERS.get("nomad_endpoint")
    const nomad_job = await env.WORKERS.get("nomad_job");

    let encoder = new TextEncoder();
    // from https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries#validating-webhook-deliveries
    async function verifySignature(secret, header, payload) {
      let parts = header.split("=");
      let sigHex = parts[1];

      let algorithm = { name: "HMAC", hash: { name: "SHA-256" } };

      let keyBytes = encoder.encode(secret);
      let extractable = false;
      let key = await crypto.subtle.importKey(
        "raw",
        keyBytes,
        algorithm,
        extractable,
        ["sign", "verify"]
      );

      let sigBytes = hexToBytes(sigHex);
      let dataBytes = encoder.encode(payload);
      let equal = await crypto.subtle.verify(
        algorithm.name,
        key,
        sigBytes,
        dataBytes
      );

      return equal;
    }
    // from https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries#validating-webhook-deliveries
    function hexToBytes(hex) {
      let len = hex.length / 2;
      let bytes = new Uint8Array(len);

      let index = 0;
      for (let i = 0; i < hex.length; i += 2) {
        let c = hex.slice(i, i + 2);
        let b = parseInt(c, 16);
        bytes[index] = b;
        index += 1;
      }

      return bytes;
    }

    function rawHtmlResponse(html) {
      return new Response(html, {
        headers: {
          "content-type": "text/html;charset=UTF-8",
        },
      });
    }

    /**
     * readRequestBody reads in the incoming request body
     * Use await readRequestBody(..) in an async function to get the string
     * @param {Request} request the incoming request to read from
     */
    async function readRequestBody(request) {
      console.log("getting request body");
      const contentType = request.headers.get("Content-Type");
      console.log(contentType);
      if (contentType == null) {
        console.log(request.status);
      } else if (contentType.includes("application/json")) {
        return JSON.stringify(await request.json());
      } else if (contentType.includes("application/text")) {
        return request.text();
      } else if (contentType.includes("text/html")) {
        return request.text();
      } else if (contentType.includes("form")) {
        const formData = await request.formData();
        const body = {};
        for (const entry of formData.entries()) {
          body[entry[0]] = entry[1];
        }
        return JSON.stringify(body);
      } else {
        // Perhaps some other type of data was submitted in the form
        // like an image, or some other binary data.
        console.log(request.status)
        return "a file";
      }
    }

    const { url } = request;
    if (url.includes("form")) {
      return rawHtmlResponse(someForm);
    }

    if (request.method === "GET") {
      return new Response("OK", { status: 226 });
    } else if (request.method === "POST") {
      // Get the secret from KV
      const secret = await env.WORKERS.get("github_webhook_secret");
      const _event = request.headers.get("x-github-event");
      if (_event == "workflow_run" || _event == "workflow_job") {
        console.log(`This was a ${_event} event`);
        const payload = await request.json();
        // Verify the Payload using the webhook secret as key
        if (
          verifySignature(
            secret,
            request.headers["X-Hub-Signature-256"],
            payload
          )
        ) {
          // Get headers and see what kind of event this was
          console.log("Payload verified");
          const access_client_id = env.CF_ACCESS_CLIENT_ID;
          const access_client_secret = env.CF_ACCESS_CLIENT_SECRET;
          const nomad_acl_token = env.NOMAD_ACL_TOKEN;
          const permitted_actions = ["queued"];
          const permitted_labels = ["self-hosted", "hah"]
          if (_event == "workflow_job") {
            const selected = permitted_labels.some(r => payload.workflow_job.labels)
            console.log(selected)
          }

          if (permitted_actions.includes(payload.action)) {
            console.log(`${payload.action}`)
            const data = btoa(
              JSON.stringify({
                repo: payload.repository.full_name,
                fork: payload.repository.fork,
                job: payload.workflow_job.name,
                run_id: payload.workflow_job.run_id
              })
            );
            // const data = btoa(JSON.stringify(payload["zen"]));

            const dispatch = {
              method: "POST",
              headers: {
                "Authorization":  "Bearer " + nomad_acl_token,
                "Content-Type": "application/json;charset=UTF-8",
                "CF-Access-Client-Id": access_client_id,
                "CF-Access-Client-Secret": access_client_secret,
              },
              body: JSON.stringify({
                Payload: data,
                Meta: {
                  REPO_FULL_NAME: payload.repository.full_name,
                  REPO_SHORT_NAME: payload.repository.name,
                  WORKFLOW_RUN: (payload.workflow_job.run_id).toString()
                },
              }),
            };
            console.log(dispatch);
            console.log(
              "https://nomad.brucellino.dev/v1/job/" + nomad_job + '/dispatch',
              dispatch
            );
            const nomad_response = await fetch(
              "https://nomad.brucellino.dev/v1/job/" + nomad_job + '/dispatch',
              dispatch
            );
            const nomad_res = await readRequestBody(nomad_response);
            console.log(nomad_res);
          }
          // console.log(JSON.stringify(await nomad_response.Response.json()))
          return new Response("OK");
        }
      } else {
        return new Response("Failed to verify Signature", { status: 403 });
      }
    }
  },
};
