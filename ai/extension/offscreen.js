// Keep the service worker from idling out. Helium MV3 drops a lone
// background WebSocket every ~20s without another context.
setInterval(() => {
  chrome.runtime.sendMessage({ type: "keepalive" }).catch(() => {});
}, 20000);
