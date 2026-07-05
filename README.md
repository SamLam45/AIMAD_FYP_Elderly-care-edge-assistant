# Elderly Care Edge Assistant (LAADR)

Edge AI caregiver system for elderly daily support — Flutter mobile app with Jetson Nano backend for voice reminders, face recognition, and real-time alerts.

**Final Year Project** · Mobile app + edge backend by Sam · Companion parenting app by teammates.

## Description

LAADR (Life Assistant and Daily Reminders) helps caregivers manage daily events for elderly users. The mobile app supports voice-controlled scheduling via Picovoice and manual event entry. A Jetson Nano edge device polls Firebase for reminder times, speaks alerts with gTTS, runs face recognition for family members, and sends FCM push notifications when unknown persons are detected.

## Tech Stack

| Layer | Technologies |
|-------|----------------|
| Mobile | Flutter, Firebase (RTDB, Storage, FCM), Picovoice (Porcupine + Rhino) |
| Edge | Python, Jetson Nano, OpenCV, face_recognition, Socket TCP, gTTS, GPIO |
| Cloud | Firebase Realtime Database as sync bridge between phone and edge |

## Project Structure

```
├── lib/          Flutter app (LAADR)
├── edge/         Jetson Nano Python services
│   ├── socket_server.py
│   ├── reminder_service.py
│   └── voice_assistant.py
└── docs/         UML diagrams (classDiagrams.puml, Sequence_Diagram_EA.puml)
```

## Quick Start

### Mobile (Flutter)

```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
# Add your Picovoice AccessKey to secrets.dart

flutter pub get
flutter run
```

### Edge (Jetson Nano)

See [edge/README.md](edge/README.md).

```bash
cd edge
cp .env.example .env
pip install -r requirements.txt
python socket_server.py
python reminder_service.py
```

## Key Features

- Voice-activated event scheduling (Rhino NLU → Firebase)
- Daily reminders with time range and alert time
- Family face registration from phone → Jetson training
- Live face recognition with unknown-person FCM alerts
- Edge-side scheduled voice reminders via Firebase polling
