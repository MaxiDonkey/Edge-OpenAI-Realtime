/*********************************************************************
 *                    INIT MODULE (Common Glue)
 *
 * OVERVIEW:
 *   Initialization logic and UI glue for audio/mic UX in hybrid apps.
 *   Handles intro message, capture auto-start, and mic icon sync.
 *
 * FEATURES:
 *   - Display and auto-hide initial intro message (id="init-message")
 *   - Automatically start audio capture on load
 *   - Maintain and expose `blockAudioSend` (window property) for mic state
 *   - Dynamic mic icon synchronization (id="svg-mic-on" / "svg-mic-off")
 *
 * PUBLIC API / GLOBALS:
 *   · window.blockAudioSend (boolean, property)
 *       → True = mic muted/blocked; False = mic open
 *       → Setter triggers icon update automatically
 *   · updateMicIcon()
 *       → Forces refresh of mic icon display state
 *
 * DEPENDENCIES:
 *   - Expects <div id="init-message"> for the intro panel
 *   - Expects <svg id="svg-mic-on"> and <svg id="svg-mic-off"> for mic icons
 *   - Requires startCapture() and post() to be defined in global scope
 *
 * DESIGN NOTES:
 *   - All behaviors are local; no host/bridge communication except via post()
 *   - Designed as a “glue” module for single-page or embedded app contexts
 *
 *********************************************************************/


// --- Init: "intro" behavior
blockAudioSend = true;
const initMsg = document.getElementById('init-message');
if (initMsg) initMsg.classList.remove('hide');
setTimeout(() => {
  blockAudioSend = false;
  chunks = [];
  if (initMsg) { 
    initMsg.classList.add('hide'); 
    setTimeout(() => initMsg?.parentNode?.removeChild(initMsg), 3500); 
  }
}, 2500);

// --- Start capture on load
startCapture().catch(e => post({ event:'audio_error', message:'setup failed', detail:String(e) }));

// --- Keep the mic icon synchronized with blockAudioSend
let _blockAudioSend = true;

function updateMicIcon() {
  const on  = document.getElementById('svg-mic-on');
  const off = document.getElementById('svg-mic-off');
  if (on)  on.style.display  = blockAudioSend ? "none"  : "inline";
  if (off) off.style.display = blockAudioSend ? "inline": "none";
}

Object.defineProperty(window, "blockAudioSend", {
  get() { return _blockAudioSend; },
  set(v) { _blockAudioSend = !!v; updateMicIcon(); }
});

window.blockAudioSend = true;

updateMicIcon();
