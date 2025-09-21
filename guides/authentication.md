## Authentication (ephemeral secrets)
- The long-lived key is resolved **in Delphi** (env/registry) and exchanged for a short-lived **client secret** used by Edge for the session.
- No durable secret is injected into the page; short TTL; renew on reconnect.

> Session loop example: `ResolveLongKey → POST /client_secret → RT.connect(secret) → WebRTC`.

### Figure 4 : Authentication Flow (API key → client_secrets → session init)
This diagram: indispensable for a secure client-side integration. The component resolves the key, creates a **short-lived** client_secret, then initializes WebRTC with that bearer; this matches the Realtime API (`client_secrets` + WebRTC `calls`).

```text
[VCL Application]
    |
    +-- Resolve API Key (env/registry/prompt)
    v
[Realtime Engine]
    |
    +-- Create Client Secret (expires_after, session)
    |         |
    |         +--> POST OpenAI /v1/realtime/client_secrets
    |               -> returns EPHEMERAL KEY
    v
[Edge WebView2 / window.RT]
    |
    +-- init(url, bearer = EPHEMERAL KEY) -> connect()
    |         +-- POST /v1/realtime/calls (SDP) -> Answer
    v
[WebRTC session established] -> DataChannel "oai-events"
```

Notes:
- Only the **ephemeral** secret is provided to `window.RT.init(...)`.
- The long-lived key never reaches the browser context.

<br>
