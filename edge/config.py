"""Load Jetson edge service configuration from environment variables."""

import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent


def _env(key: str, default: str = "") -> str:
    return os.getenv(key, default)


def _env_int(key: str, default: int) -> int:
    value = os.getenv(key)
    return int(value) if value else default


SOCKET_HOST = _env("SOCKET_HOST", "0.0.0.0")
SOCKET_PORT = _env_int("SOCKET_PORT", 1235)

IMAGE_FOLDER_PATH = _env("IMAGE_FOLDER_PATH", str(BASE_DIR / "data" / "register"))
TRAIN_MODEL_PATH = _env("TRAIN_MODEL_PATH", str(BASE_DIR / "data" / "train.pkl"))
UNKNOWN_IMAGE_PATH = _env("UNKNOWN_IMAGE_PATH", str(BASE_DIR / "data" / "unknown_person.jpg"))

FIREBASE_CREDENTIALS_PATH = _env("FIREBASE_CREDENTIALS_PATH", "")
FCM_DEVICE_TOKEN = _env("FCM_DEVICE_TOKEN", "")

FIREBASE_RTDB_URL = _env(
    "FIREBASE_RTDB_URL",
    "https://chatappflutter-99ba7-default-rtdb.firebaseio.com",
)

PICOVOICE_ACCESS_KEY = _env("PICOVOICE_ACCESS_KEY", "")
PICOVOICE_KEYWORD_PATH = _env("PICOVOICE_KEYWORD_PATH", "")
PICOVOICE_CONTEXT_PATH = _env("PICOVOICE_CONTEXT_PATH", "")

GPIO_LED_PIN = _env_int("GPIO_LED_PIN", 12)
FACE_RESIZE_PERCENT = _env_int("FACE_RESIZE_PERCENT", 30)
UNKNOWN_ALERT_COOLDOWN_SEC = _env_int("UNKNOWN_ALERT_COOLDOWN_SEC", 10)

CAMERA_PIPELINE = (
    "nvarguscamerasrc ! "
    "video/x-raw(memory:NVMM), width=(int)640, height=(int)480, "
    "format=(string)NV12, framerate=(fraction)30/1 ! "
    "nvvidconv ! video/x-raw, format=(string)BGRx ! "
    "videoconvert ! video/x-raw, format=(string)BGR ! appsink"
)


def ensure_data_dirs() -> None:
    Path(IMAGE_FOLDER_PATH).mkdir(parents=True, exist_ok=True)
    Path(TRAIN_MODEL_PATH).parent.mkdir(parents=True, exist_ok=True)
