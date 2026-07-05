"""Poll Firebase Realtime Database and speak reminders at scheduled times."""

import os
import time

from firebase import firebase
from gtts import gTTS

from config import FIREBASE_RTDB_URL


def speak_event(reminder_text: str) -> None:
    tts = gTTS(text=reminder_text, lang="en")
    output_path = "events.mp3"
    tts.save(output_path)
    os.system(f"mpg123 {output_path}")


def run_reminder_service() -> None:
    fdb = firebase.FirebaseApplication(FIREBASE_RTDB_URL, None)
    print("Reminder service started. Polling /events every second...")

    try:
        while True:
            result = fdb.get("/events", None)
            if result is not None:
                current_time = time.strftime("%H:%M", time.localtime())

                for key, value in result.items():
                    reminder_time = value["reminder"]
                    reminder = "Owner, you have a " + value["event"]
                    event_time = " at " + value["time"]

                    if current_time == reminder_time:
                        speak_event(reminder + event_time)
                        fdb.delete("/events", key)
                        print("Reminder sent and event deleted:", key)

            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopping reminder service...")


if __name__ == "__main__":
    run_reminder_service()
