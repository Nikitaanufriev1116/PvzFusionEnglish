export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return handleOptions();
    }

    if (url.pathname === "/" && request.method === "GET") {
      return withCors(new Response("ChatGPT5 proxy is running. POST /api/chat", { status: 200 }));
    }

    if (url.pathname === "/api/chat" && request.method === "POST") {
      if (!env.OPENAI_API_KEY) {
        return withCors(new Response(JSON.stringify({ error: "Missing OPENAI_API_KEY" }), { status: 500, headers: { 'Content-Type': 'application/json' } }));
      }
      let body;
      try {
        body = await request.json();
      } catch {
        return withCors(new Response(JSON.stringify({ error: "Invalid JSON body" }), { status: 400, headers: { 'Content-Type': 'application/json' } }));
      }

      const messages = Array.isArray(body?.messages) ? body.messages : [];
      const model = typeof body?.model === 'string' && body.model ? body.model : 'gpt-4o-mini';
      const temperature = typeof body?.temperature === 'number' ? body.temperature : 0.7;

      if (messages.length === 0) {
        return withCors(new Response(JSON.stringify({ error: "messages must be a non-empty array" }), { status: 400, headers: { 'Content-Type': 'application/json' } }));
      }

      const openaiResp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model,
          messages,
          temperature,
          stream: true
        })
      });

      if (!openaiResp.ok || !openaiResp.body) {
        const text = await openaiResp.text();
        return withCors(new Response(JSON.stringify({ error: `Upstream error ${openaiResp.status}`, details: text }), { status: 500, headers: { 'Content-Type': 'application/json' } }));
      }

      const headers = new Headers(openaiResp.headers);
      headers.set('access-control-allow-origin', '*');
      headers.set('content-type', 'text/event-stream; charset=utf-8');
      headers.set('cache-control', 'no-cache');
      headers.set('connection', 'keep-alive');
      headers.set('x-accel-buffering', 'no');

      return new Response(openaiResp.body, { status: 200, headers });
    }

    return withCors(new Response(JSON.stringify({ error: "Not found" }), { status: 404, headers: { 'Content-Type': 'application/json' } }));
  }
}

function handleOptions() {
  const headers = new Headers();
  headers.set('access-control-allow-origin', '*');
  headers.set('access-control-allow-headers', 'Content-Type, Authorization');
  headers.set('access-control-allow-methods', 'POST, GET, OPTIONS');
  headers.set('access-control-max-age', '86400');
  return new Response(null, { status: 204, headers });
}

function withCors(resp) {
  const headers = new Headers(resp.headers);
  headers.set('access-control-allow-origin', '*');
  return new Response(resp.body, { status: resp.status, headers });
}