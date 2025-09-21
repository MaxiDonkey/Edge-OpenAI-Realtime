# Architecture
## Three-layer split
1. **Realtime (Delphi, UI-free)**, implements Realtime API calls, signaling, turn handling, JSON normalization/hydration, and state.
2. **Edge/WebView2 (Chromium)**, hosts **RTCPeerConnection**, **MediaStream**, **DataChannel** and minimal audio UI; uses **`window.chrome.webview`** to exchange messages with Delphi. Adapter is **replaceable** later.
3. **VCL (installable component)**, public surface (properties/methods/events), lightweight settings persistence, and overridable logging/error hooks.

## Orchestration on the Delphi side
A central type, `TEdgeRealtimeWire`, orchestrates WebView2 navigation, JS init (`RT.init`), Realtime connect (`RT.connect`), signaling (offer/answer/ICE), **DataChannel**, mic capture and Edge playback, and raises events back to the VCL component.

## Figure 1 : Global Architecture (VCL component + native Edge/WebRTC)
This diagram: gives the overall view (three layers: Realtime, Edge/WebView2, VCL) and their interfaces. The project is structured as Realtime (UI-free), Edge (Chromium/WebRTC) and VCL component; WebRTC runs **inside** Edge/WebView2 (no third-party WebRTC component), using the WebView2 messaging bridge.

```text
[Application VCL]
      |
      v
[TEdgeRealtimeControl]  (VCL)
      | uses
      |---> [Realtime Engine (IRealTime)] --(client_secrets)--> [OpenAI Realtime API]
      |                                         (éphémère)
      |
      v
[TEdgeRealtimeWire]  --expose--> IDataChannel
      |                 \-------> IEdgeAudio
      | uses
      v
[Edge WebView2 (Chromium)]
      |
      v loads
[Audio UI + JS]
      |
      v provides
[window.RT API]
   |        \
   | WebRTC  \ HTTP signaling → /v1/realtime/calls (OpenAI)
   v
[RTCPeerConnection] -- DataChannel "oai-events" --> (events)
          |
          +-- Remote Audio Track --> IEdgeAudio.Player
```

Notes:
- DataChannel **“oai-events”** carries Realtime events (e.g., `session.update`, `conversation.item.create`, `response.create`).
- Remote audio track is rendered via Edge and surfaced as `IEdgeAudio` in Delphi.
- `TEdgeRealtimeControl` (VCL) → `TEdgeRealtimeWire` (bridge) → Edge page exposing `window.RT`.

<br>