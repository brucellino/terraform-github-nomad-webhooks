export default {
  async fetch(request, env) {
    /**
     * rawHtmlResponse returns HTML inputted directly
     * into the worker script
     * @param {string} html
     */
    // let nomad_endpoint = await env.WORKERS.get("nomad_endpoint")


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
      let sig = await env.WORKERS.get("github_webhook_secret");
      if (request.headers['x-hub-signature-256'] == sig) {
        const reqBody = await readRequestBody(request);
        const retBody = `The request body sent in was ${reqBody}`;
        return new Response(retBody);
      } else {
        const retBody = `Signature didn't match`;
        return new Response(retBody, {status: 403});
      }


    } else if (request.method === "GET") {
      return new Response("The request was a GET");
    }
  },
};
