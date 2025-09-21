/*********************************************************************
 *              ALERT BUBBLE / TOAST (WebView2 + Delphi Bridge)
 *
 * OVERVIEW:
 *   Simple alert/toast bubble with smooth animation, controlled either
 *   directly via JavaScript or remotely from Delphi via Edge WebView2 bridge.
 *
 * FEATURES:
 *   - Show and hide animated toast/alert bubble
 *   - Auto-hide with configurable duration
 *   - Clean CSS transitions (opacity/visibility)
 *   - Message bridge for remote (host) control
 *
 * PUBLIC API (JavaScript):
 *   · showToast(text: string, durationMs = 7000)
 *       → Show a toast with the given text for the specified duration (ms)
 *   · hideToast()
 *       → Immediately hide the toast (with fade-out)
 *
 * WEBVIEW2 BRIDGE (from Delphi/host):
 *   · { "cmd": "showToast", "text": "Hello", "durationMs": 7000 }
 *       → Show toast via PostWebMessageAsJson
 *   · { "cmd": "hideToast" }
 *       → Hide toast via PostWebMessageAsJson
 *
 * DEPENDENCIES:
 *   - Requires a <div id="toast"><span id="toast-text"></span></div> in DOM
 *   - Requires CSS for .show and .fade-out classes (opacity/display transitions)
 *   - Requires Edge WebView2 messaging (window.chrome.webview)
 *
 * DESIGN NOTES:
 *   - All appearance/animation handled by CSS; this module triggers state
 *   - Multiple calls to showToast reset the timer and override text
 *
 *********************************************************************/

(function () {
  const el = document.getElementById('toast');
  const txt = document.getElementById('toast-text');
  if (!el || !txt) return;

  let hideTimer = null;

  function clearTimers() {
    if (hideTimer) { clearTimeout(hideTimer); hideTimer = null; }
  }

  /**
   * Measure the final height without flicker
   */
  function measureAndShow() {
    const prevDisplay = el.style.display;
    const prevOpacity = el.style.opacity;

    el.style.display = 'block';
    el.style.visibility = 'hidden';
    el.style.opacity = '0';
    // Force the measurement
    // (We don't set the height: CSS handles auto-height;
    // The measurement simply ensures that the layout is stabilized)
    // eslint-disable-next-line no-unused-vars
    const _h = el.scrollHeight;

    el.style.visibility = '';
    // We use a class to manage opacity via CSS (transition)
    el.classList.add('show');
    // Cleaning up temporary inline styles
    el.style.opacity = prevOpacity || '';
    if (!prevDisplay) el.style.display = ''; // we let .show handle display:block
  }

  function showToast(text, durationMs = 7000) {
    clearTimers();

    // Updates the text
    txt.textContent = String(text ?? '');

    // Cancels any current fade-out
    el.classList.remove('fade-out');

    // Measure + appearance
    measureAndShow();

    // Auto-fade-out after durationMs
    hideTimer = setTimeout(() => {
      hideToast();
    }, Math.max(0, Number(durationMs) || 7000));
  }

  function hideToast() {
    clearTimers();
    // Start the fade
    el.classList.add('fade-out');

    // At the end of the transition, we completely hide
    const onEnd = (ev) => {
      if (ev.propertyName === 'opacity') {
        el.classList.remove('show', 'fade-out');
        el.style.display = 'none';
        el.removeEventListener('transitionend', onEnd);
      }
    };
    el.addEventListener('transitionend', onEnd);
    // To ensure the success
    setTimeout(() => {
      if (el.classList.contains('fade-out')) {
        el.classList.remove('show', 'fade-out');
        el.style.display = 'none';
      }
    }, 1500);
  }

  // Global exposure
  window.showToast = showToast;
  window.hideToast = hideToast;

  // WebView2 Bridge
  if (window.chrome && chrome.webview) {
    try {
      chrome.webview.addEventListener('message', (ev) => {
        const m = typeof ev.data === 'string'
          ? (ev.data.startsWith('{') ? JSON.parse(ev.data) : null)
          : ev.data;

        if (!m || typeof m !== 'object') return;
        switch (m.cmd) {
          case 'showToast':
            showToast(m.text, m.durationMs);
            break;
          case 'hideToast':
            hideToast();
            break;
        }
      });
    } catch { /* no-op */ }
  }
})();
