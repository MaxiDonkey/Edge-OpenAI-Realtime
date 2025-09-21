# Edge-OpenAI-Realtime (POC VCL + WebView2)
![IDE Version](https://img.shields.io/badge/Delphi-12%20Athens-ffffba) 
![WebView2](https://img.shields.io/badge/WebView2-VCL-baffc9)
![GitHub](https://img.shields.io/badge/Updated%20on%20September%2021,%202025-blue)

<br>

___

A **VCL** component that encapsulates a **UI-free Realtime** layer and an **Edge/WebView2** (Chromium) adapter to drive **WebRTC** (audio + DataChannel) inside an embedded page, enabling **real-time voice interactions** with OpenAI’s Realtime API. The POC validates the end-to-end chain **inside Edge/WebView2** with conversational perceived latency, without reusing documentation sample code, and keeps the Edge adapter **swappable**.

<br>

>[!WARNING]
> **TL;DR - Executive Summary**
>- **What it is**: a palette-ready VCL component; a UI-free Realtime layer; and an Edge/WebView2 adapter that hosts WebRTC and bridges Delphi ⇄ JS.
>- **What it proves**: live voice to voice; default **semantic_vad**; user **barge-in**; audio playback handled by Edge; rich events to observe session state.
>- **What it does *not* try to do**: native WebRTC stack outside Edge, production packaging, custom audio processing (AEC/AGC), or cloud storage.  
>  _Note: **FMX is not targeted** because Embarcadero does not provide an Edge/WebView2 component for FMX; this is a platform constraint, not a POC choice._

<br>

---

## Objective
Edge-OpenAI-Realtime ships a **VCL component** that embeds a **UI-free Realtime** layer (Delphi) and an **Edge/WebView2** adapter to orchestrate **WebRTC** (SDP/ICE, DataChannel, mic capture and playback) in the embedded page. The POC demonstrates **real-time voice dialog** with the Realtime API: mic permission, connection establishment, **turn detection** enabled by default (**semantic_vad**), smooth **barge-in**, TTS synthesis and **audio playback**.

Authentication uses **ephemeral client secrets**: no long-lived key in the page. The component exposes a **clean event model** (WebRTC state, listen start/stop, volume, open, etc.) and relies on **JSON interop** (polymorphic payloads, normalization/hydration, safe memory handling). The goal is **to prove the end-to-end real-time chain** in Edge/WebView2 and keep the Edge adapter replaceable, not to build a polished UI.

<br>

___

## POC Scope 
This POC is **strictly** VCL + Edge/WebView2. **FMX is not targeted** because Embarcadero does not provide an Edge/WebView2 component for FMX. It **does not** include a native WebRTC stack outside Edge, **does not** cover productization (packaging/installer/signing), **does not** implement specialized audio processing (custom AEC/AGC), and **does not** address cloud storage or a production backend.

**Single priority:** validate WebRTC behavior in Edge/WebView2 and Realtime orchestration (latency feel, turn detection, barge-in, ICE lifecycle);  **not** ship a finished product.

<br>

___

## Architecture
### Three-layer split
1. **Realtime (Delphi, UI-free)**, implements Realtime API calls, signaling, turn handling, JSON normalization/hydration, and state.
2. **Edge/WebView2 (Chromium)**, hosts **RTCPeerConnection**, **MediaStream**, **DataChannel** and minimal audio UI; uses **`window.chrome.webview`** to exchange messages with Delphi. Adapter is **replaceable** later.
3. **VCL (installable component)**, public surface (properties/methods/events), lightweight settings persistence, and overridable logging/error hooks.

### Orchestration on the Delphi side
A central type, `TEdgeRealtimeWire`, orchestrates WebView2 navigation, JS init (`RT.init`), Realtime connect (`RT.connect`), signaling (offer/answer/ICE), **DataChannel**, mic capture and Edge playback, and raises events back to the VCL component.

### Figure 1 : Global Architecture (VCL component + native Edge/WebRTC)
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

___

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

___

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

___

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

___

## Reconnect / AutoResume - PeerConnection loss and recovery
Documents robustness: disconnection events, clean close, reconnection, and optional re-application of parameters/history.

### Figure 5 : Reconnect / AutoResume Sequence
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

<br>

___

## Component Surface (API)
### Properties (excerpt)
- `TurnDetection`: `semantic_vad` (default) | `server_vad` | `null` (manual control).
- `VadSemantic`: pass-through knobs for eagerness/interrupt behavior **as supported by the Realtime API**.
- `VadServer`: pass-through knobs (`threshold`, `silence_ms`, `prefix_padding_ms`, `idle_timeout_ms`) **when/if exposed by the API**.
- `PersistOptions`: simple persistence for developer profiles.

> Note: VAD behavior is controlled by the Realtime API. The component **does not implement local VAD**; it only configures/forwards supported settings or allows **manual control** when `TurnDetection = null`.

### Methods (excerpt)
- `Connect`, `Disconnect`, session/PeerConnection lifecycle.
- `Commit`, end the user turn when `TurnDetection = null`.
- `ResponseCreate`, explicit response request (aligned with Realtime).

### Events (excerpt)
- `OnRTOpen`, `OnRTPcState`, `OnRTDataChannel`, `OnRTListen`, `OnRTVolumeChanged`, `OnRTMicClick`, `OnRTError`.

<br>

___

## Quick Demo (POC)
1. **Prereqs**
   - Windows 10+ with **WebView2 Runtime**.
   - Recent Delphi VCL (Win32/Win64).
2. **Setup**
   - Install the component package; drop it from the palette; add a `TEdgeBrowser` (or let the component manage its embedded instance).
3. **Minimal test**
   - Run the demo app → click **Listen** → speak → hear a spoken reply; observe PC/DC states and input level.
4. **Barge-in**
   - Speak while playback is ongoing; observe `OnRTListen` and `OnRTVolumeChanged`.

<br>

___

## Acceptance Criteria
- Smooth voice↔voice dialog with **conversational perceived latency**.
- **Turn detection** enabled by default, switchable, and **disablable** with manual control.
- **Barge-in** works during playback.
- **ICE lifecycle** works in normal connect/reconnect; diagnostics are actionable.
- **No long-lived secret** ever injected into the page.

<br>

___

## Caller Example 
The component ships with a demo app that contains the **reference caller**. To avoid drift, this README **does not copy** the code; refer to:

- `samples/VCLDemo/MainForm.pas` (project `samples/VCLDemo/VCLDemo.dproj`).

**Running the demo**
1. Open `samples/VCLDemo/VCLDemo.dproj` in Delphi.
2. Ensure **WebView2 Runtime** is installed.
3. Build & run (F9), click **Listen**, speak, confirm playback and events.

> If the component API evolves, the **demo file is the authoritative source**. If you paste a snippet into the README at release time, copy it **from that file**.

<br>

___

## License
This project is licensed under the [MIT](https://choosealicense.com/licenses/mit/) License.
