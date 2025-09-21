/*********************************************************************
 *                AUDIO CAPTURE SIMULATION (VAD + Animation)
 *
 * OVERVIEW:
 *   Visual simulation of microphone audio capture and voice activity
 *   detection (VAD), with real-time waveform animation for user feedback.
 *   Designed for embedding in hybrid desktop apps (Edge WebView2 + Delphi).
 *
 * FEATURES:
 *   - RMS-based visual Voice Activity Detection (VAD)
 *   - Real-time waveform animation on <canvas>
 *   - Microphone control (toggle, param update, on/off)
 *   - Two-way bridge with host via chrome.webview messaging
 *
 * PUBLIC API / MESSAGE COMMANDS:
 *   - startCapture                         Start microphone capture and animation
 *   - setVadParams({})                     Update VAD parameters (threshold, silenceMs, timeslice)
 *   - setVadThreshold(value)               Set VAD threshold (number)
 *   - setVadSilenceMs(value)               Set VAD silence timeout (ms)
 *   - setTimeslice(value)             	    Set VAD timeslice window (ms)
 *   - mic_on / mic_off / mic_toggle        Enable, disable, or toggle microphone
 *   - block_audio_send                     Force local mic OFF
 *   - unblock_audio_send                   Force local mic ON
 *   - close                                Request to close/cancel capture panel
 *
 * EXPORTED GLOBALS:
 *   - window.reinitWebRTC()                Reinitialize upstream WebRTC (if present)
 *
 * EVENT EMISSIONS (to host):
 *   - audio_capture_started                Capture pipeline started successfully
 *   - audio_error                          Error during capture init or processing
 *   - audio_vad_params                     VAD params changed ({previous, current})
 *   - mic_button_clicked                   User toggled mic button (on/off)
 *   - close_click                          User or host requested panel close
 *   - audio_warn                           Unknown/unsupported command received
 *
 * DEPENDENCIES:
 *   - Expects a <canvas id="wave"> element in the DOM
 *   - Expects buttons with id="btn-micro" and id="btn-close"
 *   - Requires Edge WebView2 messaging (window.chrome.webview)
 *
 * DESIGN NOTES:
 *   - All audio processing is local/visual; no backend streaming involved
 *   - No UI or rendering except for waveform and mic controls
 *   - Intended for real-time UX feedback in a host-managed app
 *
 *********************************************************************/


// ===================================================================
// Parameters (visual VAD only)
// ===================================================================
const DEFAULT_VAD = { threshold: 0.5, silenceMs: 1500, timeslice: 300 };
let vad = { ...DEFAULT_VAD };


// ===================================================================
// Global captures
// ===================================================================
let analyser = null, dataArray = null, audioCtx = null;
let captureStream = null;

// Display
let rmsMicEMA = 0;

// ===================================================================
// Wave rendering
// ===================================================================
const wave = document.getElementById('wave');
const ctx  = wave ? wave.getContext('2d') : null;

function waveColor() { return blockAudioSend ? "#29e7ff" : "#22ff44"; }

function clearWave() {
  if (!ctx || !wave) return;
  ctx.clearRect(0, 0, wave.width, wave.height);
}

function drawWave(flat = false) {
  if (!ctx || !wave) return;

  ctx.fillStyle = "#212121";
  ctx.fillRect(0, 0, wave.width, wave.height);
  ctx.beginPath();

  if (flat || !dataArray) {
    ctx.moveTo(0, wave.height / 2);
    ctx.lineTo(wave.width, wave.height / 2);
  } else {
    const step = Math.max(1, Math.floor(dataArray.length / Math.max(1, wave.width)));
    for (let x = 0; x < wave.width; x++) {
      const i = x * step;
      const y = wave.height / 2 - (dataArray[i] || 0) * (wave.height / 0.62);
      x === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
  }

  const c = waveColor();
  ctx.strokeStyle = c;
  ctx.shadowColor = c;
  ctx.shadowBlur = 6;
  ctx.lineWidth = 2.7;
  ctx.stroke();
  ctx.shadowBlur = 0;
}


// ===================================================================
// VAD-Voice Activity Detection: loop (visual only)
// ===================================================================
function fastHypot(buf) {
  let s = 0;
  for (let i = 0; i < buf.length; i++) {
    const v = buf[i];
    s += v * v;
  }
  return Math.sqrt(s);
}

function vadLoop() {
  if (!analyser) { requestAnimationFrame(vadLoop); return; }

  analyser.getFloatTimeDomainData(dataArray);
  const rms = fastHypot(dataArray);

  // visual smoothing
  rmsMicEMA = rmsMicEMA + 0.25 * (rms - rmsMicEMA);

  // vague rendering: flat line when below the threshold
  drawWave(rms <= vad.threshold);

  requestAnimationFrame(vadLoop);
}


// ===================================================================
// Capture API
// ===================================================================
async function startCapture() {
  // Close the old AudioContext
  try { if (audioCtx && typeof audioCtx.close === "function") await audioCtx.close(); } catch {}
  audioCtx = null;

  // Stop the old flow
  try { if (captureStream) captureStream.getTracks().forEach(t => t.stop()); } catch {}
  captureStream = null;

  // Reset analyzer
  analyser = null;
  dataArray = null;

  // Capture → Analyze
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
    });

    captureStream = stream;
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();

    const src = audioCtx.createMediaStreamSource(stream);

    analyser = audioCtx.createAnalyser();
    analyser.fftSize = 512;
    dataArray = new Float32Array(analyser.fftSize);
    src.connect(analyser);

    post({ event: 'audio_capture_started' });
    requestAnimationFrame(vadLoop);

  } catch (e) {
    post({ event: 'audio_error', message: 'getUserMedia failed', detail: String(e) });
  }
}

// ===================================================================
// Mic & VAD parameters
// ===================================================================
function reinitWebRTC() {
  if (window.RT) {
    if (typeof RT.close === "function") RT.close();
    setTimeout(() => { if (typeof RT.connect === "function") RT.connect(); }, 250);
  }
}

function toggleMic() {
  blockAudioSend = !blockAudioSend;
  post({ event: 'mic_button_clicked', value: blockAudioSend ? 'off' : 'on' });

  if (blockAudioSend) {
    // Cut local capture wave animation
    //try { if (captureStream) { captureStream.getTracks().forEach(t => t.stop()); captureStream = null; } } catch {}
    // Tell Realtime to turn off the microphone
    if (window.RT && typeof RT.micOff === "function") RT.micOff();
  } else {
    startCapture();
    reinitWebRTC();
  }
}

function setVadParams(params = {}) {
  const prev = { ...vad };
  vad = { ...vad, ...params };
  post({ event: 'audio_vad_params', previous: prev, current: vad });
}


// ===================================================================
// UI button hooks
// ===================================================================
const _btnMicro = document.getElementById('btn-micro');
if (_btnMicro) _btnMicro.onclick = toggleMic;

const _btnClose = document.getElementById('btn-close');
if (_btnClose) _btnClose.onclick = () => post({ event: 'close_click' });


// ===================================================================
// WebView message bridge (chrome.webview)
// ===================================================================
if (window.chrome && chrome.webview) {
  try {
    chrome.webview.addEventListener('message', ev => {
      const m = typeof ev.data === 'string'
        ? (ev.data.startsWith('{') ? JSON.parse(ev.data) : ev.data)
        : ev.data;

      if (!m || typeof m !== 'object' || !('cmd' in m)) return;

      switch (m.cmd) {
        case 'startCapture':          startCapture(); break;

        // Visual VAD
        case 'setVadParams':          setVadParams(m.params || {}); break;
        case 'setVadThreshold':       setVadParams({ threshold: Number(m.value) || vad.threshold }); break;
        case 'setVadSilenceMs':       setVadParams({ silenceMs: Number(m.value) || vad.silenceMs }); break;
        case 'setTimeslice':          setVadParams({ timeslice: Number(m.value) || vad.timeslice }); break;

        // Microphone
        case 'mic_on':                if (blockAudioSend) toggleMic(); break;
        case 'mic_off':               if (!blockAudioSend) toggleMic(); break;
        case 'mic_toggle':            toggleMic(); break;
        case 'block_audio_send':      if (!blockAudioSend) toggleMic(); break;
        case 'unblock_audio_send':    if (blockAudioSend)  toggleMic(); break;

        case 'close':                 post({ event: 'close_click' }); break;

        default:
          post({ event: 'audio_warn', message: `Unknown command (capture): ${m.cmd}` });
      }
    });
  } catch {}
}

window.reinitWebRTC = reinitWebRTC;

