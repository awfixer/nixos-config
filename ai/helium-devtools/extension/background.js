const BACKOFF_MS = [500, 1000, 2000, 5000, 10000];
// Helium serves chrome internals as helium://. chrome:// still appears on
// some tabs and the debugger API still rejects them as chrome://.
const RESTRICTED_URL = /^(helium|chrome|about|devtools|chrome-extension):/;

function isRestrictedUrl(url) {
  if (url === "about:blank" || url === "about:srcdoc") return false;
  return RESTRICTED_URL.test(url || "");
}

let ws = null;
let lastError = "";
let backoffIdx = 0;
let reconnectTimer = null;
let connecting = false;

function setLastError(msg) {
  lastError = msg || "";
  if (chrome.storage && chrome.storage.session) {
    chrome.storage.session.set({ lastError });
  }
}

function serializeTab(tab) {
  return {
    id: tab.id,
    windowId: tab.windowId,
    url: tab.url || "",
    title: tab.title || "",
    active: !!tab.active,
    status: tab.status || "",
  };
}

function isConnected() {
  return !!(ws && ws.readyState === 1);
}

function send(obj) {
  if (!isConnected()) return;
  ws.send(JSON.stringify(obj));
}

function reply(id, ok, resultOrError) {
  if (ok) {
    send({ type: "reply", id, ok: true, result: resultOrError });
    return;
  }
  const error = String(resultOrError || "rpc_failed");
  setLastError(error);
  send({ type: "reply", id, ok: false, error });
}

function chromeCallback(resolve, reject, map) {
  return (value) => {
    if (chrome.runtime.lastError) {
      reject(new Error(chrome.runtime.lastError.message));
      return;
    }
    resolve(map ? map(value) : value);
  };
}

function attachTab(tabId) {
  return new Promise((resolve, reject) => {
    chrome.tabs.get(tabId, (tab) => {
      if (chrome.runtime.lastError) {
        reject(new Error(`attach_refused: ${chrome.runtime.lastError.message}`));
        return;
      }
      const url = (tab && tab.url) || "";
      if (isRestrictedUrl(url)) {
        reject(new Error("attach_refused: restricted_url"));
        return;
      }
      chrome.debugger.attach({ tabId }, "1.3", () => {
        if (chrome.runtime.lastError) {
          let msg = chrome.runtime.lastError.message || "attach failed";
          if (/chrome:\/\//i.test(msg)) {
            msg = msg.replace(/chrome:\/\//gi, "helium://");
          }
          reject(new Error(`attach_refused: ${msg}`));
          return;
        }
        resolve({ attached: true });
      });
    });
  });
}

function detachTab(tabId) {
  return new Promise((resolve, reject) => {
    chrome.debugger.detach({ tabId }, chromeCallback(resolve, reject, () => ({ attached: false })));
  });
}

function sendCommand(tabId, method, params) {
  return new Promise((resolve, reject) => {
    chrome.debugger.sendCommand({ tabId }, method, params || {}, chromeCallback(resolve, reject));
  });
}

async function evalInPage(tabId, expression) {
  await attachTab(tabId);
  const raw = await sendCommand(tabId, "Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true,
  });
  if (raw && raw.exceptionDetails) {
    const details = raw.exceptionDetails;
    const exc = details.exception || {};
    const text = exc.description || details.text || "eval exception";
    throw new Error(`eval_failed: ${text}`);
  }
  const result = (raw && raw.result) || {};
  return { result: result.value, type: result.type };
}

async function setRequestIntercept(payload) {
  const tabId = payload.tabId;
  if (payload.enabled === false) {
    await sendCommand(tabId, "Fetch.disable", {});
    return { enabled: false };
  }
  await sendCommand(tabId, "Fetch.enable", {
    patterns: payload.patterns || [{ urlPattern: "*" }],
  });
  return { enabled: true };
}

async function runOp(op, payload) {
  switch (op) {
    case "list_tabs": {
      const tabs = await chrome.tabs.query({});
      return { tabs: tabs.map(serializeTab) };
    }
    case "attach":
      return attachTab(payload.tabId);
    case "detach":
      return detachTab(payload.tabId);
    case "send_command":
      return sendCommand(payload.tabId, payload.method, payload.params);
    case "create_tab": {
      const tab = await chrome.tabs.create({ url: payload.url || "about:blank" });
      if (tab.status === "complete") {
        return { tab: serializeTab(tab) };
      }
      const finished = await new Promise((resolve) => {
        const tabId = tab.id;
        const timer = setTimeout(() => {
          chrome.tabs.onUpdated.removeListener(onUpdated);
          chrome.tabs.get(tabId, (latest) => resolve(latest || tab));
        }, 8000);
        function onUpdated(updatedId, change, updated) {
          if (updatedId === tabId && change.status === "complete") {
            clearTimeout(timer);
            chrome.tabs.onUpdated.removeListener(onUpdated);
            resolve(updated);
          }
        }
        chrome.tabs.onUpdated.addListener(onUpdated);
      });
      return { tab: serializeTab(finished) };
    }
    case "close_tab":
      await chrome.tabs.remove(payload.tabId);
      return {};
    case "activate_tab":
      await chrome.tabs.update(payload.tabId, { active: true });
      return {};
    case "list_extensions":
      return { extensions: await chrome.management.getAll() };
    case "set_extension_enabled":
      await chrome.management.setEnabled(payload.id, payload.enabled);
      return { id: payload.id, enabled: payload.enabled };
    case "get_cookies": {
      const cookies = await chrome.cookies.getAll({ domain: payload.domain });
      return { cookies };
    }
    case "eval":
      return evalInPage(payload.tabId, payload.expression);
    case "set_request_intercept":
      return setRequestIntercept(payload);
    default:
      throw new Error(`unknown_op: ${op}`);
  }
}

async function onBridgeMessage(event) {
  let data;
  try {
    data = JSON.parse(event.data);
  } catch {
    return;
  }
  if (data.type === "hello_ok") {
    backoffIdx = 0;
    setLastError("");
    try {
      const tabs = await chrome.tabs.query({});
      send({ type: "tabs_snapshot", tabs: tabs.map(serializeTab) });
    } catch (err) {
      setLastError(String(err.message || err));
    }
    return;
  }
  if (data.type === "hello_fail") {
    setLastError(data.error || "hello_fail");
    return;
  }
  if (data.type !== "cmd") return;
  try {
    const result = await runOp(data.op, data.payload || {});
    reply(data.id, true, result);
  } catch (err) {
    reply(data.id, false, err && err.message ? err.message : err);
  }
}

function scheduleReconnect() {
  if (reconnectTimer) return;
  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
    return;
  }
  const delay = BACKOFF_MS[Math.min(backoffIdx, BACKOFF_MS.length - 1)];
  backoffIdx = Math.min(backoffIdx + 1, BACKOFF_MS.length - 1);
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectBridge();
  }, delay);
}

async function connectBridge() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
    return;
  }
  if (connecting) return;
  connecting = true;
  try {
    const res = await fetch(chrome.runtime.getURL("config.json"));
    if (!res.ok) throw new Error(`config.json HTTP ${res.status}`);
    const cfg = await res.json();
    if (!cfg.bridgeUrl || !cfg.token) throw new Error("config.json missing bridgeUrl or token");
    const socket = new WebSocket(cfg.bridgeUrl);
    ws = socket;
    connecting = false;
    socket.addEventListener("open", () => {
      socket.send(JSON.stringify({ type: "hello", token: cfg.token, v: 1 }));
    });
    socket.addEventListener("message", onBridgeMessage);
    socket.addEventListener("error", () => {
      setLastError("websocket error");
    });
    socket.addEventListener("close", () => {
      if (ws === socket) ws = null;
      if (!lastError) setLastError("bridge closed");
      scheduleReconnect();
    });
  } catch (err) {
    setLastError(String(err.message || err));
    connecting = false;
    scheduleReconnect();
  }
}

function emitTabEvent(kind, tab) {
  send({ type: "tab_event", kind, tab });
}

async function ensureOffscreen() {
  if (!chrome.offscreen || !chrome.runtime.getContexts) return;
  const existing = await chrome.runtime.getContexts({
    contextTypes: ["OFFSCREEN_DOCUMENT"],
  });
  if (existing && existing.length) return;
  await chrome.offscreen.createDocument({
    url: "offscreen.html",
    reasons: ["WORKERS"],
    justification: "Keep the Helium DevTools bridge WebSocket alive",
  });
}

function armAlarm() {
  if (!chrome.alarms) return;
  chrome.alarms.create("helium-devtools-bridge", { periodInMinutes: 0.5 });
}

chrome.runtime.onInstalled.addListener(() => {
  ensureOffscreen().catch(() => {});
  armAlarm();
  connectBridge();
});
chrome.runtime.onStartup.addListener(() => {
  ensureOffscreen().catch(() => {});
  armAlarm();
  connectBridge();
});
chrome.runtime.onConnect.addListener(() => {
  connectBridge();
});
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (!msg) return;
  if (msg.type === "keepalive") {
    connectBridge();
    return;
  }
  if (msg.type !== "status") return;
  sendResponse({ connected: isConnected(), lastError });
});
if (chrome.alarms) {
  chrome.alarms.onAlarm.addListener((alarm) => {
    if (alarm.name === "helium-devtools-bridge") connectBridge();
  });
}

chrome.tabs.onCreated.addListener((tab) => {
  emitTabEvent("created", serializeTab(tab));
});
chrome.tabs.onRemoved.addListener((tabId, info) => {
  emitTabEvent("removed", { id: tabId, windowId: info.windowId });
});
chrome.tabs.onUpdated.addListener((_tabId, _change, tab) => {
  emitTabEvent("updated", serializeTab(tab));
});
chrome.tabs.onActivated.addListener((info) => {
  chrome.tabs.get(info.tabId, (tab) => {
    if (chrome.runtime.lastError || !tab) {
      emitTabEvent("activated", { id: info.tabId, windowId: info.windowId, active: true });
      return;
    }
    emitTabEvent("activated", serializeTab(tab));
  });
});

chrome.debugger.onEvent.addListener((source, method, params) => {
  if (source.tabId == null) return;
  send({ type: "cdp_event", tabId: source.tabId, method, params: params || {} });
});

if (chrome.storage && chrome.storage.session) {
  chrome.storage.session.get(["lastError"], (st) => {
    if (!lastError && typeof st.lastError === "string") lastError = st.lastError;
  });
}

ensureOffscreen().catch(() => {});
armAlarm();
connectBridge();
