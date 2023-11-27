export default {
  async fetch(request, env) {
    /**
     * rawHtmlResponse returns HTML inputted directly
     * into the worker script
     * @param {string} html
     */
    // let nomad_endpoint = await env.WORKERS.get("nomad_endpoint")

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
      const contentType = request.headers.get("content-type");
      if (contentType.includes("application/json")) {
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
        return "a file";
      }
    }

    const { url } = request;
    if (url.includes("form")) {
      return rawHtmlResponse(someForm);
    }
    if (request.method === "POST") {
      // Get the secret from KV
      let secret = await env.WORKERS.get("github_webhook_secret");
      let payload = await request.body
      if (verifySignature(secret, request.headers['X-Hub-Signature-256'], payload)) {
        const payload = btoa(JSON.stringify(payload.body))
        const dispatch = {
          method: "POST",
          headers: {
            "content-type": "application/json;charset=UTF-8",
          },
        };
        const nomad_response = await fetch("http://nomad.brucellino.dev/v1/job/dispatch/dispatch?Payload=" +payload, dispatch)
        console.log(nomad_response.json())
        return new Response("OK")
      }
      else {
        return new Response("Failed to verify Signature", { status: 403})
      }

    }
  },
};
