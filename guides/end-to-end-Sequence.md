## End-to-End Sequence (high level)
1. **Edge init** → load an embedded page that exposes an `RT` JS module.
2. **Realtime session** → Delphi resolves long key (env/registry) and creates an **ephemeral client secret** via a server endpoint.
3. **WebRTC negotiation** → `RT.connect(secret)` creates an offer; SDP is posted back to Delphi; Delphi calls Realtime to get the answer; ICE flows via the bridge.
4. **Audio in/out** → mic via `getUserMedia`; default **semantic_vad** for turns; TTS responses are played back by Edge.
5. **Interaction** → user **barge-in**; **DataChannel** for commands (e.g., `commit`, `response.create`) and lightweight telemetry.

### Figure 2 : Runtime Sequence (init, negotiation, Realtime exchange)
This diagram: makes explicit the initialization chain up to DataChannel exchanges (`session.update`, `conversation.item.create`, `response.create`). The POC creates an **ephemeral** client_secret then negotiates via `/v1/realtime/calls`; channel **“oai-events”** is used for Realtime events.

```text
  Application VCL
      |
  TEdgeRealtimeControl.InitializeRuntime
      |
      +--> Resolve API key -> Realtime Engine -> Create ClientSecret [Ephemeral]
      |                                               (ClientSecret.Value)
      |
      v
  Edge WebView2 (navigate to audio UI)
      |
      +--> window.RT.init(url, bearer) -> window.RT.connect()
      |          |
      |          +--> WebRTC: createOffer -> setLocalDescription
      |          |                     |
      |          |                     -> POST /v1/realtime/calls -> setRemoteDescription
      |          |
      |          +--> On track added -> audio playback
      |          |
      |          +--> DataChannel open -> session.created
      |
      +--> window.RT.updateSession(patch) -> session.update
      |
      +--> conversation.item.create / response.create (via DataChannel)
``` 

Notes:
- Offer/answer via `POST /v1/realtime/calls`; audio track added → playback; **DataChannel open** → `session.created`.
- Session updates (e.g., model/audio/VAD) are sent via `window.RT.updateSession(patch)` → `session.update`.

<br>
