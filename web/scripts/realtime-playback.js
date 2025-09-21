/*********************************************************************
 *                  AUDIO BRIDGE & PLAYBACK (Realtime-driven)
 *
 * OVERVIEW:
 *   Minimal audio bridge for playback control between the host WebView
 *   (Edge WebView2) and the underlying Realtime driver.
 *   Handles local audio stop/reset and volume (with amplification).
 *
 * FEATURES:
 *   - Stop playback and reset position (stopAudio)
 *   - Volume control, including >1 amplification via WebAudio API
 *   - Message bridge for playback commands from host
 *   - Playback event forwarding (intended: audio_meta, audio_time, audio_play,
 *     audio_pause, audio_ended; actual event wiring managed externally)
 *
 * PUBLIC API:
 *   Via WebView2 message bridge (chrome.webview):
 *     · stop                               Stop playback and reset audio to 0
 *     · setVolume(v)                       Set playback volume; supports values >1 if WebAudio available
 *
 *   Global JS functions (window):
 *     · window.stopAudio()                 Stop/reset playback (for Delphi/host scripting)
 *     · window.setVolume(v)                Set volume/amplification (for Delphi/host scripting)
 *
 * EVENT EMISSIONS:
 *   (Expected from external playback pipeline; not emitted directly here.)
 *   - audio_meta, audio_time, audio_play, audio_pause, audio_ended
 *
 * DESIGN NOTES:
 *   - All other playback controls (source, stream, toggles, etc.) are intentionally omitted.
 *   - This module assumes an external orchestrator manages <audio id="player"> events.
 *
 * DEPENDENCIES:
 *   - Requires <audio id="player"> in DOM
 *   - Requires Edge WebView2 messaging (window.chrome.webview)
 *
 *********************************************************************/

// --- CONSTANTS
const _player = document.getElementById('player');
const ENDED_EPSILON_THRESHOLD = 0.05;
const STOP_RESET_DELAY_MS = 10;
const TIMEUPDATE_MIN_INTERVAL_MS = 100;

// ===================================================================
// Helpers
// ===================================================================

/** Post message to Delphi bridge (Edge WebView2). */
const post = (o) => { try { chrome?.webview?.postMessage(o); } catch {} };

// ===================================================================
// Ended event handling
// ===================================================================

let audioEndedSent = false;

function resetEndedFlag() { audioEndedSent = false; }

// ===================================================================
// Playback controls
// ===================================================================

function stopAudio() {
  try { _player.pause(); } catch {}
  setTimeout(() => { try { _player.currentTime = 0; } catch {} }, STOP_RESET_DELAY_MS);
  resetEndedFlag();
  try { if (typeof reinitWebRTC === "function") reinitWebRTC(); } catch {}
  try { if (typeof stopMatrixProcessingAnim === "function") stopMatrixProcessingAnim(); } catch {}
}

// ===================================================================
// Volume
// ===================================================================

let gainNode = null, audioCtxBoost = null, srcNode = null;

/** Set playback volume, with >1 amplification via WebAudio when needed. */
function setVolume(v) {
  v = Number(v) || 0;

  if (v <= 1) {
    if (gainNode) { try { gainNode.gain.value = 1; } catch {} }
    try { _player.volume = Math.max(0, v); } catch {}
    return;
  }

  if (!audioCtxBoost) {
    try {
      audioCtxBoost = new (window.AudioContext || window.webkitAudioContext)();
      srcNode = audioCtxBoost.createMediaElementSource(_player);
      gainNode = audioCtxBoost.createGain();
      srcNode.connect(gainNode).connect(audioCtxBoost.destination);
    } catch {
      // fallback: if WebAudio unavailable, clamp to 1
      try { _player.volume = 1; } catch {}
      return;
    }
  }

  try { _player.volume = 1; } catch {}
  try { gainNode.gain.value = v; } catch {}
}

// ===================================================================
// WebView message bridge (chrome.webview)
// ===================================================================

if (window.chrome && chrome.webview) {
  try {
    chrome.webview.addEventListener('message', ev => {
      const m = typeof ev.data === 'string'
        ? (ev.data.startsWith('{') ? JSON.parse(ev.data) : ev.data)
        : ev.data;

      if (m && typeof m === 'object' && 'cmd' in m) {
        switch (m.cmd) {
          case 'stop':      stopAudio(); break;
          case 'setVolume': setVolume(m.value); break;
          default:
            break;
        }
      }
    });
  } catch {}
}

// ===================================================================
// Global exports (for Delphi)
// ===================================================================

window.stopAudio = stopAudio;
window.setVolume = setVolume;

