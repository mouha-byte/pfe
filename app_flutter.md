Create a production-ready Flutter mobile application.

FEATURES:
- Clean UI dashboard showing system status
- Fetch data from REST API (Flask backend)
- Display:
  - flashCount
  - defect name
  - priority (A or B)
  - status (OPEN / CLOSED)
- Real-time refresh every 2 seconds
- Local notifications when:
  - priority = A
  - or status = OPEN
- Use Provider or Riverpod for state management
- Use http package for API calls
- Use flutter_local_notifications for alerts

SCREENS:
1. Home screen:
   - Card list of defects
   - Color:
     - Red = priority A
     - Orange = priority B
     - Green = no issue

2. Detail screen:
   - Show full defect info
   - Show flash count explanation

MODEL (JSON):
{
  "flash": 4,
  "defect": "Capteur position",
  "priority": "B",
  "status": "OPEN"
}

BONUS:
- Add manual refresh button
- Add offline fallback (cached data)