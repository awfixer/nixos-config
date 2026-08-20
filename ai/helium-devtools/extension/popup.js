chrome.runtime.connect();
chrome.runtime.sendMessage({ type: "status" }, (resp) => {
  const state = document.getElementById("state");
  const error = document.getElementById("error");
  if (chrome.runtime.lastError || !resp) {
    state.textContent = "down";
    error.textContent =
      (chrome.runtime.lastError && chrome.runtime.lastError.message) || "";
    return;
  }
  state.textContent = resp.connected ? "connected" : "down";
  error.textContent = resp.lastError || "";
});
