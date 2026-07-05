"""Picovoice wake-word assistant for Jetson Nano."""

import argparse
import os
import struct
import wave
from typing import Optional

import cv2
import requests
from gtts import gTTS
from picovoice import (
    Picovoice,
    PicovoiceActivationError,
    PicovoiceActivationLimitError,
    PicovoiceActivationRefusedError,
    PicovoiceActivationThrottledError,
    PicovoiceError,
    PicovoiceInvalidArgumentError,
)
from pvrecorder import PvRecorder

from config import PICOVOICE_ACCESS_KEY, PICOVOICE_CONTEXT_PATH, PICOVOICE_KEYWORD_PATH


def open_camera_pipeline(
    capture_width=720,
    capture_height=480,
    display_width=360,
    display_height=240,
    framerate=30,
    flip_method=0,
) -> str:
    return (
        "nvarguscamerasrc ! "
        "video/x-raw(memory:NVMM), "
        f"width=(int){capture_width}, height=(int){capture_height}, "
        f"framerate=(fraction){framerate}/1 ! "
        f"nvvidconv flip-method={flip_method} ! "
        f"video/x-raw, width=(int){display_width}, height=(int){display_height}, "
        "format=(string)BGRx ! videoconvert ! "
        "video/x-raw, format=(string)BGR ! appsink drop=True"
    )


def face_detect() -> None:
    window_title = "Face Detect"
    face_cascade = cv2.CascadeClassifier(
        "/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml"
    )
    eye_cascade = cv2.CascadeClassifier(
        "/usr/share/opencv4/haarcascades/haarcascade_eye.xml"
    )
    video_capture = cv2.VideoCapture(open_camera_pipeline(), cv2.CAP_GSTREAMER)

    if not video_capture.isOpened():
        print("Unable to open camera")
        return

    try:
        cv2.namedWindow(window_title, cv2.WINDOW_AUTOSIZE)
        while True:
            ret, frame = video_capture.read()
            if not ret:
                break

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.3, 5)

            for (x, y, w, h) in faces:
                cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), 2)
                roi_gray = gray[y : y + h, x : x + w]
                roi_color = frame[y : y + h, x : x + w]
                eyes = eye_cascade.detectMultiScale(roi_gray)
                for (ex, ey, ew, eh) in eyes:
                    cv2.rectangle(
                        roi_color,
                        (ex, ey),
                        (ex + ew, ey + eh),
                        (0, 255, 0),
                        2,
                    )

            if cv2.getWindowProperty(window_title, cv2.WND_PROP_AUTOSIZE) >= 0:
                cv2.imshow(window_title, frame)
            else:
                break

            key_code = cv2.waitKey(10) & 0xFF
            if key_code in (27, ord("q")):
                break
    finally:
        video_capture.release()
        cv2.destroyAllWindows()


def get_weather_data() -> dict:
    url = (
        "https://data.weather.gov.hk/weatherAPI/opendata/"
        "weather.php?dataType=flw&lang=tc"
    )
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()


def say_today_weather() -> None:
    weather_data = get_weather_data()
    if "warningMessage" in weather_data:
        print("Unable to fetch weather data")
        return

    weather_forecast = weather_data["forecastDesc"]
    tts = gTTS(text=f"今天的天氣：{weather_forecast}", lang="zh-tw")
    tts.save("weather_forecast.mp3")
    os.system("mpg123 weather_forecast.mp3")
    print(f"今天的天氣：{weather_forecast}")


def run_voice_assistant(
    access_key: str,
    keyword_path: str,
    context_path: str,
    audio_device_index: int = -1,
    output_path: Optional[str] = None,
) -> None:
    def wake_word_callback() -> None:
        print("[wake word]")

    def inference_callback(inference) -> None:
        intent = inference.intent if inference.is_understood else None
        if intent == "iot":
            face_detect()
        elif intent == "day":
            print("Say today's date and weekday")
        elif intent == "weather":
            say_today_weather()
        else:
            print("Unsupported command:", intent)

    picovoice = Picovoice(
        access_key=access_key,
        keyword_path=keyword_path,
        wake_word_callback=wake_word_callback,
        context_path=context_path,
        inference_callback=inference_callback,
    )

    recorder = PvRecorder(
        frame_length=picovoice.frame_length,
        device_index=audio_device_index,
    )
    recorder.start()
    print("Listening...")

    wav_file = None
    if output_path is not None:
        wav_file = wave.open(output_path, "wb")
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(picovoice.sample_rate)

    try:
        while True:
            pcm = recorder.read()
            if wav_file is not None:
                wav_file.writeframes(struct.pack("h" * len(pcm), *pcm))
            picovoice.process(pcm)
    except KeyboardInterrupt:
        print("Stopping voice assistant...")
    finally:
        recorder.delete()
        picovoice.delete()
        if wav_file is not None:
            wav_file.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Jetson Picovoice assistant")
    parser.add_argument("--access-key", default=PICOVOICE_ACCESS_KEY)
    parser.add_argument("--keyword-path", default=PICOVOICE_KEYWORD_PATH)
    parser.add_argument("--context-path", default=PICOVOICE_CONTEXT_PATH)
    parser.add_argument("--audio-device-index", type=int, default=-1)
    parser.add_argument("--output-path", default=None)
    parser.add_argument("--show-audio-devices", action="store_true")
    args = parser.parse_args()

    if args.show_audio_devices:
        for index, device in enumerate(PvRecorder.get_available_devices()):
            print(f"Device {index}: {device}")
        return

    if not args.access_key or not args.keyword_path or not args.context_path:
        raise SystemExit(
            "Set PICOVOICE_ACCESS_KEY, PICOVOICE_KEYWORD_PATH, and "
            "PICOVOICE_CONTEXT_PATH in edge/.env"
        )

    try:
        run_voice_assistant(
            access_key=args.access_key,
            keyword_path=args.keyword_path,
            context_path=args.context_path,
            audio_device_index=args.audio_device_index,
            output_path=args.output_path,
        )
    except PicovoiceInvalidArgumentError as exc:
        raise SystemExit(f"Invalid Picovoice arguments: {exc}") from exc
    except (
        PicovoiceActivationError,
        PicovoiceActivationLimitError,
        PicovoiceActivationRefusedError,
        PicovoiceActivationThrottledError,
        PicovoiceError,
    ) as exc:
        raise SystemExit(f"Picovoice initialization failed: {exc}") from exc


if __name__ == "__main__":
    main()
