const historyListEl = document.getElementById('history-list');
const flashEl = document.getElementById('flash-value');
const defectEl = document.getElementById('defect-value');
const priorityEl = document.getElementById('priority-value');
const statusEl = document.getElementById('status-value');
const timestampEl = document.getElementById('timestamp-value');
const connectionEl = document.getElementById('connection-value');
const priorityPanel = document.getElementById('priority-panel');

const notifyBtn = document.getElementById('notify-btn');
const soundBtn = document.getElementById('sound-btn');

const history = [];
let lastNotificationTimestamp = null;
let soundEnabled = false;

function updateDashboard(data) {
  flashEl.textContent = data.flash;
  defectEl.textContent = data.defect;
  priorityEl.textContent = data.priority;
  statusEl.textContent = data.status;
  timestampEl.textContent = new Date(data.timestamp).toLocaleString();

  priorityPanel.classList.remove('priority-a', 'priority-b');
  priorityEl.classList.remove('priority-a', 'priority-b');
  statusEl.classList.remove('status-open', 'status-closed', 'critical-blink');

  if (data.priority === 'A') {
    priorityPanel.classList.add('priority-a');
    priorityEl.classList.add('priority-a');
  } else {
    priorityPanel.classList.add('priority-b');
    priorityEl.classList.add('priority-b');
  }

  if (data.status === 'OPEN') {
    statusEl.classList.add('status-open', 'critical-blink');
  } else {
    statusEl.classList.add('status-closed');
  }

  pushHistory(data);
  notifyIfCritical(data);
}

function pushHistory(item) {
  history.unshift(item);
  if (history.length > 10) {
    history.pop();
  }

  historyListEl.innerHTML = '';
  for (const event of history) {
    const li = document.createElement('li');
    const critical = event.priority === 'A' || event.status === 'OPEN';
    li.className = `history-item${critical ? ' critical' : ''}`;

    li.innerHTML = `
      <span>${event.defect}</span>
      <span>Flash: ${event.flash}</span>
      <span>Priorite ${event.priority}</span>
      <span>${event.status} • ${new Date(event.timestamp).toLocaleTimeString()}</span>
    `;

    historyListEl.appendChild(li);
  }
}

async function requestNotificationPermission() {
  if (!('Notification' in window)) {
    notifyBtn.textContent = 'Notifications non supportees';
    notifyBtn.disabled = true;
    return;
  }

  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    notifyBtn.textContent = 'Notifications actives';
  } else {
    notifyBtn.textContent = 'Notifications refusees';
  }
}

function notifyIfCritical(data) {
  const critical = data.priority === 'A' || data.status === 'OPEN';
  if (!critical) {
    return;
  }

  if (lastNotificationTimestamp === data.timestamp) {
    return;
  }
  lastNotificationTimestamp = data.timestamp;

  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification('Alerte systeme', {
      body: `${data.defect} • Priorite ${data.priority} • ${data.status}`,
      tag: data.timestamp,
    });
  }

  playAlertSound();
}

function playAlertSound() {
  if (!soundEnabled) {
    return;
  }

  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const oscillator = audioContext.createOscillator();
  const gainNode = audioContext.createGain();

  oscillator.type = 'triangle';
  oscillator.frequency.value = 750;
  gainNode.gain.value = 0.08;

  oscillator.connect(gainNode);
  gainNode.connect(audioContext.destination);

  oscillator.start();
  oscillator.stop(audioContext.currentTime + 0.18);
}

function connectStream() {
  connectionEl.textContent = 'Connecte au flux SSE';
  const source = new EventSource('/stream');

  source.addEventListener('status', (event) => {
    connectionEl.textContent = 'Connecte au flux SSE';
    const data = JSON.parse(event.data);
    updateDashboard(data);
  });

  source.onerror = () => {
    connectionEl.textContent = 'Deconnecte - tentative de reconnexion...';
  };
}

async function bootstrap() {
  try {
    const response = await fetch('/status');
    const initialData = await response.json();
    updateDashboard(initialData);
  } catch (_) {
    connectionEl.textContent = 'Impossible de charger le statut initial';
  }

  connectStream();
}

notifyBtn.addEventListener('click', requestNotificationPermission);

soundBtn.addEventListener('click', () => {
  soundEnabled = !soundEnabled;
  soundBtn.textContent = soundEnabled ? 'Son actif' : 'Activer son';
});

bootstrap();
