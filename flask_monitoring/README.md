# Flask Monitoring Dashboard

Backend Flask + frontend web en temps reel pour la supervision des defauts.

## Fonctionnalites

- Endpoint `GET /status` avec donnees aleatoires
- Endpoint `GET /stream` en Server-Sent Events (mise a jour toutes les 2s)
- Dashboard web moderne (dark mode)
- Notifications navigateur si priorite A ou statut OPEN
- Clignotement visuel sur statut OPEN
- Historique des 10 derniers evenements
- Alerte sonore optionnelle

## Installation

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Lancement

```bash
python app.py
```

Puis ouvrir http://127.0.0.1:5000

## Integration Flutter

L'application Flutter lit le backend sur `http://10.0.2.2:5000` par defaut (Android emulator).
Vous pouvez changer la base URL au build:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.21:5000
```
