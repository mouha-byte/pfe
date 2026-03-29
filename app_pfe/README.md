# app_pfe

Flutter mobile dashboard connected to the Flask monitoring backend.

## Prerequisites

- Flutter SDK installed
- Android emulator or physical Android phone
- Python 3 installed

## 1) Run the Flask API + Web dashboard

From workspace root (`application_salsabil`):

```powershell
py flask_monitoring\app.py
```

Then open:

- Web dashboard: `http://127.0.0.1:5000`
- API status endpoint: `http://127.0.0.1:5000/status`

## 2) Run Flutter app

From `app_pfe` folder:

```powershell
flutter pub get
flutter run
```

Default Flutter API base URL is set to Android emulator loopback:

- `http://10.0.2.2:5000`

## If you use a physical phone

Use your PC LAN IP instead of `10.0.2.2`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.X.Y:5000
```

How to find your PC IP (Windows):

```powershell
ipconfig
```

Use IPv4 address from your active adapter.

## Troubleshooting

- Flask must be running before Flutter fetches `/status`.
- Phone and PC must be on the same Wi-Fi network.
- Keep Windows Firewall open for Python on private networks.
- If API calls fail, open in phone browser:
	- `http://<PC_IP>:5000/status`
	- If this fails, network/firewall is the issue.
