## Deployment Diagram - VCL App + WebView2 + OpenAI Realtime
Clarifies the runtime footprint (EXE, WebView2Loader.dll, local web resources) and Internet calls (client_secrets + WebRTC calls).

### Figure 3 - Deployment
This diagram: shows what runs locally vs. what goes over the network.

```text
[Windows Machine]
      |
      +-- [Process: Delphi VCL Application (.exe)]
              |
              +-- [TEdgeRealtimeControl / TEdgeRealtimeWire]
              |        |
              |        +-- [TEdgeBrowser (WebView2)]
              |        |       - Native WebRTC (PC, DC)
              |        |       - Bridge: window.chrome.webview
              |        |
              |        +-- [Local web resources] (WebPath, e.g., audio.html)
              |
              +-- [Dependency] WebView2Loader.dll

      |
      +-- Internet
             |
             +-- [OpenAI Realtime REST]
             |       - POST /v1/realtime/client_secrets → EPHEMERAL KEY
             |
             +-- [OpenAI Realtime WebRTC]
                     - POST /v1/realtime/calls (SDP)
                     - Audio stream + DataChannel "oai-events"
```

Notes:
- Local assets (e.g., `audio.html`, JS) are loaded by `TEdgeBrowser`; the **native** Edge WebRTC engine is used (PC/DC).
- Bridge is `window.chrome.webview`.
- Internet endpoints:
  - `POST /v1/realtime/client_secrets` → **ephemeral** key
  - `POST /v1/realtime/calls` (SDP) → answer; media + **oai-events** DataChannel thereafter.

<br>
