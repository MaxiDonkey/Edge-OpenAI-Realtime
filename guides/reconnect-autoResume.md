# Reconnect / AutoResume - PeerConnection loss and recovery
Documents robustness: disconnection events, clean close, reconnection, and optional re-application of parameters/history.

## Figure 5 : Reconnect / AutoResume Sequence
This diagram: shows the lifecycle on disconnect (`OnRTPcState = disconnected/failed`), controlled shutdown, and restart; if `AutoResume = True`, re-inject history and re-apply session settings.

```text
[Active Session]
    |
OnRTPcState = disconnected/failed  -> OnClosed
    |
Controlled shutdown:
  - window.RT.close() (page)
  - TEdgeRealtimeWire.Close()
    |
Reconnection:
  - WebView2 + RT.init/RT.connect()
  - createOffer → /v1/realtime/calls → setRemoteDescription
    |
DataChannel open → OnRTDataChannel / OnRTOpen / OnRTPcState
    |
AutoResume = True?
  - InjectFromFile(...) (history)
  - session.update (model/audio/VAD)
    |
Operational session → OnRTListen (oai_event)
```

Notes:
- Close sequence: `window.RT.close()` (page) + `TEdgeRealtimeWire.Close()` (Delphi).
- Reconnect: `RT.init/RT.connect()` → new offer → `/v1/realtime/calls` → set remote answer → DataChannel open → `OnRTDataChannel/OnRTOpen/OnRTPcState`.
- Optional resume: `InjectFromFile(...)` (history) + `session.update` (model/audio/VAD).
