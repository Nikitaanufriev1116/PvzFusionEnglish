/*
  Chat UI logic with streaming responses via SSE from a proxy endpoint.
  Configure `window.CHATGPT5_PROXY_URL` in site/config.js.
*/

const storageKey = "chatgpt5.history.v1";
const chatEl = document.getElementById("chat");
const promptEl = document.getElementById("prompt");
const sendBtn = document.getElementById("sendBtn");
const newChatBtn = document.getElementById("newChatBtn");
const modelSelect = document.getElementById("modelSelect");

const proxyBaseUrl = (typeof window.CHATGPT5_PROXY_URL === "string" && window.CHATGPT5_PROXY_URL.trim()) || "";

/** @typedef {{ role: 'system'|'user'|'assistant', content: string }} ChatMessage */
/** @type {ChatMessage[]} */
let messages = loadHistory();

renderAllMessages(messages);

promptEl.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    onSend();
  }
});

sendBtn.addEventListener("click", onSend);
newChatBtn.addEventListener("click", () => {
  messages = [];
  saveHistory(messages);
  renderAllMessages(messages);
  promptEl.focus();
});

function onSend() {
  const text = promptEl.value.trim();
  if (!text) return;
  if (!proxyBaseUrl) {
    alert("Сначала настройте адрес прокси в site/config.js (window.CHATGPT5_PROXY_URL)");
    return;
  }
  const model = modelSelect.value || "gpt-4o-mini";

  appendMessage({ role: "user", content: text });
  promptEl.value = "";
  promptEl.style.height = "";

  const pendingAssistantMsg = { role: "assistant", content: "" };
  appendMessage(pendingAssistantMsg);

  streamChatCompletion(messages, model, (chunk) => {
    pendingAssistantMsg.content += chunk;
    updateLastAssistantBubble(pendingAssistantMsg.content);
  }).then(() => {
    messages.push(pendingAssistantMsg);
    saveHistory(messages);
  }).catch((err) => {
    updateLastAssistantBubble(`Ошибка: ${String(err)}`);
  });
}

function loadHistory() {
  try {
    const raw = localStorage.getItem(storageKey);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed;
  } catch (_) {
    return [];
  }
}

function saveHistory(msgs) {
  try {
    localStorage.setItem(storageKey, JSON.stringify(msgs));
  } catch (_) {
    /* ignore */
  }
}

function renderAllMessages(msgs) {
  chatEl.innerHTML = "";
  if (msgs.length === 0) {
    const hello = document.createElement("div");
    hello.className = "message message--assistant";
    hello.innerHTML = `
      <div class="message__avatar">🤖</div>
      <div class="message__bubble">
        Привет! Я ChatGPT5. Задайте вопрос, и я отвечу.
      </div>
    `;
    chatEl.appendChild(hello);
    return;
  }
  for (const m of msgs) {
    appendMessage(m);
  }
}

function appendMessage(msg) {
  const wrapper = document.createElement("div");
  wrapper.className = `message message--${msg.role === "user" ? "user" : "assistant"}`;
  const avatar = document.createElement("div");
  avatar.className = "message__avatar";
  avatar.textContent = msg.role === "user" ? "🙂" : "🤖";
  const bubble = document.createElement("div");
  bubble.className = "message__bubble";
  bubble.textContent = msg.content;
  wrapper.appendChild(avatar);
  wrapper.appendChild(bubble);
  chatEl.appendChild(wrapper);
  chatEl.scrollTo({ top: chatEl.scrollHeight, behavior: "smooth" });
  if (msg.role === "user") {
    messages.push(msg);
    saveHistory(messages);
  }
}

function updateLastAssistantBubble(text) {
  const nodes = chatEl.querySelectorAll(".message--assistant .message__bubble");
  if (nodes.length === 0) return;
  nodes[nodes.length - 1].textContent = text;
  chatEl.scrollTo({ top: chatEl.scrollHeight });
}

async function streamChatCompletion(history, model, onDelta) {
  chatEl.setAttribute("aria-busy", "true");
  const url = `${proxyBaseUrl.replace(/\/$/, "")}/api/chat`;
  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ messages: history, model, stream: true })
  });

  if (!resp.ok) {
    chatEl.setAttribute("aria-busy", "false");
    const text = await resp.text();
    throw new Error(`HTTP ${resp.status}: ${text}`);
  }

  const reader = resp.body.getReader();
  const decoder = new TextDecoder("utf-8");
  let buffer = "";

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split(/\r?\n/);
      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim();
        if (!line.startsWith("data:")) continue;
        const data = line.slice(5).trim();
        if (data === "[DONE]") {
          chatEl.setAttribute("aria-busy", "false");
          return;
        }
        try {
          const json = JSON.parse(data);
          const delta = json?.choices?.[0]?.delta?.content;
          if (typeof delta === "string" && delta.length > 0) {
            onDelta(delta);
          }
        } catch (_) {
          /* ignore parse errors */
        }
      }
      buffer = lines[lines.length - 1];
    }
  } finally {
    chatEl.setAttribute("aria-busy", "false");
  }
}