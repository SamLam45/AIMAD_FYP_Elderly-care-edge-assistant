# Edge AI backend (Jetson Nano)

Python services extracted from `Life_assistant.ipynb`.

## Services

| Script | Purpose |
|--------|---------|
| `socket_server.py` | Face registration, training, live recognition, FCM alerts |
| `reminder_service.py` | Poll Firebase `/events` and speak reminders |
| `voice_assistant.py` | Picovoice wake-word commands (weather, camera, date) |

## Setup on Jetson

```bash
cd edge
cp .env.example .env
# Edit .env with your Firebase credentials, Picovoice key, and paths

pip install -r requirements.txt
# On Jetson: sudo pip install Jetson.GPIO
```

## Run

```bash
python socket_server.py
python reminder_service.py
python voice_assistant.py
```

Default socket port is **1235** (must match `AppConfig.jetsonPort` in the Flutter app).
