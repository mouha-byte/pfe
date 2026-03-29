Create a full-stack real-time monitoring system with Flask backend and a web frontend (HTML, CSS, JavaScript).

BACKEND (Flask):
- Endpoint: GET /status
- Return JSON:
{
  "flash": 4,
  "defect": "Capteur position",
  "priority": "B",
  "status": "OPEN",
  "timestamp": "2026-01-01T10:00:00"
}
- Generate random data every request
- Add endpoint: /stream (Server-Sent Events or WebSocket) for real-time updates
- Send new data every 2 seconds

FRONTEND (HTML/CSS/JS):
- Single page dashboard
- Clean modern UI (cards)

DISPLAY:
- Flash count
- Defect name
- Priority (A = red, B = orange)
- Status (OPEN = blinking red, CLOSED = green)
- Timestamp

REAL-TIME:
- Use EventSource (SSE) or WebSocket
- Update UI automatically every 2 seconds (no refresh)

NOTIFICATION:
- Browser notification when:
  - priority = A
  - OR status = OPEN

STYLE:
- Dark mode
- Card layout
- Animated blinking for critical alerts

BONUS:
- History list (last 10 events)
- Sound alert for critical issues