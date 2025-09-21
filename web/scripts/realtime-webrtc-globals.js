/*********************************************************************
 *                REALTIME WEBRTC GLOBALS (realtime-webrtc-globals.js)
 *
 * OVERVIEW:
 *   Provides a self-contained global object (window.RT) for managing
 *   Realtime WebRTC audio sessions, data channels, and session state,
 *   designed for hybrid desktop apps (Edge WebView2 + Delphi host).
 *
 * KEY FEATURES:
 *   - Full lifecycle management of a WebRTC audio session (mic, signaling, playback)
 *   - Single DataChannel for OAI/assistant events and control messages
 *   - Audio capture, playback, and client-side VAD/energy probe (RMS, hysteresis)
 *   - Event bridge: dispatches connection, audio, and error events to host
 *   - Minimal state; all host communication via JSON-serializable messages
 *
 * PUBLIC API (window.RT):
 *   · init(url, bearer)                    Initialize session params (endpoint, auth)
 *   · setAudioElement(elOrId)              Set the target HTMLAudioElement for playback
 *   · connect()                            Start mic, create PeerConnection & DataChannel, start session
 *   · updateSession(patch)                 Send session.update (patch object)
 *   · respond(responsePatch)               Send response.create (custom audio response params)
 *   · commit()                             Commit input audio buffer and request response
 *   · cancel()                             Cancel response generation
 *   · truncate(ms)                         Truncate last assistant audio item at given ms
 *   · clearOutputAudio()                   Clear output audio buffer
 *   · micOff()                             Stop mic & remove from PeerConnection
 *   · sendEvent(objOrJsonString)           Send custom event over DataChannel
 *   · close()                              Gracefully close session & cleanup
 *   · state()                              Snapshot of connection & playback state
 *   · setLocalDescription(kind, sdp)       Set local SDP (host-driven fallback)
 *   · setRemoteDescription(kind, sdp)      Set remote SDP (host-driven fallback)
 *   · addIceCandidate(line, mid, mline)    Add ICE candidate (host-driven fallback)
 *   · createDataChannel(label)             Create a new DataChannel (fallback)
 *   · attachLocalMicrophone()              Re-attach local mic stream to PeerConnection
 *   · closeDataChannel(label)              Close DataChannel by label (fallback)
 *
 * HOST EVENT EMISSIONS:
 *   - rt_js_ready, rt_connected, rt_closed, rt_pc_state
 *   - rt_dc_open, rt_dc_close, rt_error, rt_mic_attached
 *   - rt_track_added, rt_event_sent, oai_event
 *   - audio_waiting, audio_stalled, audio_autoplay_blocked
 *   - audio_track_muted, audio_track_unmuted, audio_track_ended
 *   - audio_active, audio_inactive, audio_ended
 *
 * DEPENDENCIES:
 *   - Requires Edge WebView2 messaging bridge (window.chrome.webview)
 *   - Expects an <audio> element with id="player" or one provided via setAudioElement
 *
 * DESIGN NOTES:
 *   - Client-side energy probe disables server-side VAD/NR by default
 *   - Minimal UI: intended for use in host-managed environments
 *   - All state and events are JSON-serializable for safe host integration
 *
 *********************************************************************/


(() => {
  const post = (o) => { try { chrome?.webview?.postMessage?.(o); } catch {} };

  const S = {
    url: null,       // e.g. "https://api.openai.com/v1/realtime?model=gpt-realtime"
    bearer: null,    // ek_... (short-lived)
    session0: {},    // patch session.update initial
    pc: null,
    dc: null,
    mic: null,
    audioEl: null,
    lastAssistantAudioItemId: null,
    currentPlaybackMs: 0,
    connected: false,
    dcReady: false,
    pcState: 'new',

    // Additions for audio activity detection (non-regressive)
    audioActive: false,
    audioAnalyzer: null,
    audioSourceNode: null,
    audioRaf: null,
    audioCtx: null
  };

  function _guardDC() {
    if (!S.dc || S.dc.readyState !== 'open') {
      post({ event: 'rt_error', message: 'DataChannel not open' });
      return false;
    }
    return true;
  }

  // Additions: Audio energy detection (RMS + hysteresis)
  function _startEnergyProbe(stream) {
    try {
      if (!S.audioCtx) S.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      S.audioSourceNode = S.audioCtx.createMediaStreamSource(stream);
      const analyser = S.audioCtx.createAnalyser();
      analyser.fftSize = 2048;
      S.audioSourceNode.connect(analyser);
      S.audioAnalyzer = analyser;

      const buf = new Float32Array(analyser.fftSize);
      let active = false;
      let lastCrossUp = 0, lastCrossDown = 0;

      // Thresholds/timeouts (loose by default; adjustable without interruption)
      const TH_UP = 0.01;     // RMS to declare active
      const TH_DOWN = 0.005;  // RMS to declare inactive (hysteresis)
      const T_UP = 120;       // Continuous ms > TH_UP
      const T_DOWN = 1200;    // continuous ms < TH_DOWN

      function tick() {
        analyser.getFloatTimeDomainData(buf);
        let sum = 0;
        for (let i = 0; i < buf.length; i++) { const v = buf[i]; sum += v * v; }
        const rms = Math.sqrt(sum / buf.length);
        const now = performance.now();

        if (!active) {
          if (rms > TH_UP) {
            if (lastCrossUp === 0) lastCrossUp = now;
            if (now - lastCrossUp >= T_UP) {
              active = true;
              S.audioActive = true;
              post({ event: 'audio_active', itemId: S.lastAssistantAudioItemId, rms });
            }
          } else {
            lastCrossUp = 0;
          }
        } else {
          if (rms < TH_DOWN) {
            if (lastCrossDown === 0) lastCrossDown = now;
            if (now - lastCrossDown >= T_DOWN) {
              active = false;
              S.audioActive = false;
              post({ event: 'audio_inactive', itemId: S.lastAssistantAudioItemId });
            }
          } else {
            lastCrossDown = 0;
          }
        }

        S.audioRaf = requestAnimationFrame(tick);
      }

      S.audioRaf = requestAnimationFrame(tick);
    } catch (e) {
      post({ event: 'rt_error', message: 'Audio energy probe failed: ' + String(e) });
    }
  }

  function _stopEnergyProbe() {
    try { if (S.audioRaf) cancelAnimationFrame(S.audioRaf); } catch {}
    S.audioRaf = null;
    try { S.audioSourceNode?.disconnect?.(); } catch {}
    S.audioSourceNode = null;
    S.audioAnalyzer = null;
    // NOTE: Do not close S.audioCtx to be able to reuse the same context if necessary
  }

  // End of energy additions

  function _wireAudioTrack(ev) {
    const [stream] = ev.streams || [];
    if (!stream) return;
    if (!S.audioEl) S.audioEl = document.querySelector('#player') || new Audio();
    S.audioEl.srcObject = stream;

    // HTMLAudioElement Pipeline Events
    S.audioEl.onwaiting = () => post({ event: 'audio_waiting' });
    S.audioEl.onstalled = () => post({ event: 'audio_stalled' });

    S.audioEl.ontimeupdate = () => {
      S.currentPlaybackMs = (S.audioEl.currentTime || 0) * 1000;
    };
    S.audioEl.onended = () => post({ event: 'audio_ended' });

    // WebRTC track signals (presence/absence of frames)
    const track = ev.track;
    if (track) {
      track.onmute = () => post({ event: 'audio_track_muted' });
      track.onunmute = () => post({ event: 'audio_track_unmuted' });
      track.onended = () => post({ event: 'audio_track_ended' });
    }

    // Real audio activity detection
    _startEnergyProbe(stream);

    S.audioEl.play().catch(() => {
      // Autoplay blocked — the app can call player.play() on the JS side if desired
      post({ event: 'audio_autoplay_blocked' });
    });

    post({ event: 'rt_track_added' });
  }

  function _onDCMessage(ev) {
    let data = ev.data;
    try { data = JSON.parse(data); } catch {}
    // Memorize the audio assistant item if available (useful for truncate)
    if (data?.type === 'response.output_item.added' || data?.type === 'response.output_item.done') {
      const item = data.item;
      if (item?.type === 'message' && item?.role === 'assistant') {
        S.lastAssistantAudioItemId = item.id || S.lastAssistantAudioItemId;
      }
    }
    post({ event: 'oai_event', data });
  }

  async function init(url, bearer) {
    S.url = String(url || '');
    S.bearer = String(bearer || '');
    return true;
  }

  function setAudioElement(elOrId) {
    let el = elOrId;
    if (typeof elOrId === 'string') el = document.getElementById(elOrId);
    if (el instanceof HTMLAudioElement) {
      S.audioEl = el;
      return true;
    }
    return false;
  }

  async function connect() {
    if (!S.url || !S.bearer) {
      post({ event: 'rt_error', message: 'init(url,bearer) required before connect()' });
      return false;
    }

    // media (microphone)
    S.mic = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
    });

    // PC + DC
    S.pc = new RTCPeerConnection();
    S.dc = S.pc.createDataChannel('oai-events');

    S.pc.ontrack = _wireAudioTrack;
    S.dc.onmessage = _onDCMessage;

    S.dc.onopen = () => { S.dcReady = true; post({ event: 'rt_dc_open' }); };
    S.dc.onclose = () => { S.dcReady = false; post({ event: 'rt_dc_close' }); };
    S.pc.onconnectionstatechange = () => {
      S.pcState = S.pc.connectionState;
      post({ event: 'rt_pc_state', state: S.pcState });
    };

    S.mic.getAudioTracks().forEach(t => S.pc.addTrack(t, S.mic));

    // SDP offer/answer
    const offer = await S.pc.createOffer();
    await S.pc.setLocalDescription(offer);

    const resp = await fetch(S.url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${S.bearer}`, 'Content-Type': 'application/sdp' },
      body: offer.sdp
    });
    const answerSdp = await resp.text();
    await S.pc.setRemoteDescription({ type: 'answer', sdp: answerSdp });

    S.sessionReady = false;

    // IMPORTANT: Session.update initial; disable VAD/NR server if using VAD client
    const initPatch = {
      session: {
        type: 'realtime',
        output_modalities: ['audio'],
        audio: {
          input: { turn_detection: null, noise_reduction: null },
          output: { speed: S.session0?.audio?.output?.speed || 1.0 }
        },
        ...S.session0
      }
    };

    // We can send a little after the DC opening; otherwise we buffer
    const sendInit = () => {
      if (S.dc && S.dc.readyState === 'open') {
        S.dc.send(JSON.stringify(initPatch));
        S.sessionReady = true;
      } else {
        setTimeout(sendInit, 30);
      }
    };
    sendInit();

    S.connected = true;
    post({ event: 'rt_connected' });
    return true;
  }

  function updateSession(patch) {
    console.log("updateSession PATCH:", patch, typeof patch);
    if (!_guardDC()) return false;
    const msg = { type: 'session.update', session: patch || {} };
    S.dc.send(JSON.stringify(msg));
    return true;
  }

  function commit() {
      if (!_guardDC()) return false;

      // We finalize the input buffer
      S.dc.send(JSON.stringify({ type: 'input_audio_buffer.commit' }));

      // An audio response is explicitly requested
      // (Use the voice set at the root level of the session, see S.session0.voice)
      const voice = (S.session0 && S.session0.voice) ? S.session0.voice : 'ballad';

      S.dc.send(JSON.stringify({
        type: "response.create",
        response: {
          modalities: ["audio"],
          audio: { voice: voice }
        }
      }));

      return true;
    }

  function cancel() {
    if (!_guardDC()) return false;
    S.dc.send(JSON.stringify({ type: 'response.cancel' }));
    return true;
  }

  function truncate(ms) {
    if (!_guardDC()) return false;
    if (!S.lastAssistantAudioItemId) return false;
    const audio_end_ms = Number.isFinite(ms) ? Math.max(0, Math.floor(ms)) : Math.floor(S.currentPlaybackMs || 0);
    S.dc.send(JSON.stringify({
      type: 'conversation.item.truncate',
      item_id: S.lastAssistantAudioItemId,
      content_index: 0,
      audio_end_ms
    }));
    return true;
  }

  function clearOutputAudio() {
    if (!_guardDC()) return false;
    S.dc.send(JSON.stringify({ type: 'output_audio_buffer.clear' }));
    return true;
  }

  async function close() {
    _stopEnergyProbe();
    try { S.dc?.close?.(); } catch {}
    try { S.pc?.close?.(); } catch {}
    try { S.mic?.getTracks?.().forEach(t => t.stop()); } catch {}
    const was = { connected: S.connected, pcState: S.pcState };
    S.connected = false; S.dcReady = false; S.pcState = 'closed';
    post({ event: 'rt_closed', was });
    return true;
  }

  function state() {
    // Return a simple snapshot (JSON.stringify-able for ExecuteScript)
    return {
      connected: !!S.connected,
      dcReady: !!S.dcReady,
      pcState: S.pcState,
      lastAssistantAudioItemId: S.lastAssistantAudioItemId,
      currentPlaybackMs: S.currentPlaybackMs
    };
  }

  function respond(responsePatch) {
    if (!_guardDC()) return false;
    const msg = {
      type: 'response.create',
      response: {
        modalities: ['audio'],
        ...responsePatch
      }
    };
    S.dc.send(JSON.stringify(msg));
    return true;
  }

  function micOff() {
    // Delete the audio track from the PC + stop the stream
    if (S.mic) {
      S.mic.getTracks().forEach(track => track.stop());
      S.mic = null;
    }
    if (S.pc) {
      S.pc.getSenders().forEach(sender => {
        if (sender.track && sender.track.kind === "audio") {
          try { S.pc.removeTrack(sender); } catch {}
        }
      });
    }
    _stopEnergyProbe();
  }

  function sendEvent(eventObj) {
    try {
      if (!_guardDC()) throw new Error("DataChannel not open");
      // Allow passing a string or JSON object
      if (typeof eventObj === 'string') eventObj = JSON.parse(eventObj);
      S.dc.send(JSON.stringify(eventObj));
      post({ event: "rt_event_sent", payload: eventObj });
      return true;
    } catch (e) {
      post({ event: "rt_event_send_failed", reason: String(e) });
      return false;
    }
  }

  // Internal helpers
  function _ensurePC() {
    if (S.pc) return true;
    try {
      S.pc = new RTCPeerConnection();
      S.pc.ontrack = _wireAudioTrack;
      S.pc.onconnectionstatechange = () => {
        S.pcState = S.pc.connectionState;
        post({ event: 'rt_pc_state', state: S.pcState });
      };
      return true;
    } catch (e) {
      post({ event: 'rt_error', message: 'ensurePC failed: ' + String(e) });
      return false;
    }
  }

  async function _attachMicIfMissing() {
    if (!S.mic) {
      S.mic = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
      });
      S.mic.getAudioTracks().forEach(t => S.pc.addTrack(t, S.mic));
    }
  }

  // bridges (exports)
  async function setLocalDescription(kind, sdp) {
    if (!_ensurePC()) return false;
    // optional: attach the microphone if you also connect the audio in fallback
    // await _attachMicIfMissing();
    const desc = { type: kind, sdp };
    await S.pc.setLocalDescription(desc);
    return true;
  }

  async function setRemoteDescription(kind, sdp) {
    if (!S.pc) { post({ event:'rt_error', message:'pc missing for setRemoteDescription' }); return false; }
    const desc = { type: kind, sdp };
    await S.pc.setRemoteDescription(desc);
    return true;
  }

  function addIceCandidate(candidateLine, sdpMid, sdpMLineIndex) {
    if (!S.pc) { post({ event:'rt_error', message:'pc missing for addIceCandidate' }); return false; }
    return S.pc.addIceCandidate({ candidate: candidateLine, sdpMid, sdpMLineIndex });
  }

  function createDataChannel(label) {
    if (!_ensurePC()) return false;
    S.dc = S.pc.createDataChannel(label || 'oai-events');
    S.dc.onmessage = _onDCMessage;
    S.dc.onopen = () => { S.dcReady = true; post({ event: 'rt_dc_open' }); };
    S.dc.onclose = () => { S.dcReady = false; post({ event: 'rt_dc_close' }); };
    return true;
  }

  async function attachLocalMicrophone() {
    try {
      if (!S.pc) {
        post({ event: 'rt_error', message: 'attachLocalMicrophone: PeerConnection not ready' });
        return false;
      }
      if (S.mic) return true; // already attached

      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
      });
      S.mic = stream;
      stream.getAudioTracks().forEach(t => S.pc.addTrack(t, stream));

      // Restart the energy probe if necessary
      _startEnergyProbe(stream);

      post({ event: 'rt_mic_attached' });
      return true;
    } catch (e) {
      post({ event: 'rt_error', message: 'attachLocalMicrophone failed: ' + String(e) });
      return false;
    }
  }

  function closeDataChannel(label) {
    try {
      if (!S.dc) return false;  // TODO: if multiple DCs, close by label
      S.dc.close();
      return true;
    } catch (e) {
      post({ event: 'rt_error', message: 'closeDataChannel failed: ' + String(e) });
      return false;
    }
  }

  // Expose global API
  window.RT = {
    init, setAudioElement, connect, updateSession,
    commit, cancel, truncate, clearOutputAudio,
    close, state, respond, micOff, sendEvent,
    setLocalDescription, setRemoteDescription,
    addIceCandidate, createDataChannel,
    attachLocalMicrophone, closeDataChannel
  };

  // Signal ready
  post({ event: 'rt_js_ready' });
})();

