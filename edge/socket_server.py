"""
TCP socket server for LAADR mobile app <-> Jetson Nano communication.

Commands:
  - send image and name
  - train data
  - open camera
"""

import base64
import os
import pickle
import socket
import time

import cv2
import face_recognition
import firebase_admin
from firebase_admin import credentials, messaging

from config import (
    CAMERA_PIPELINE,
    FCM_DEVICE_TOKEN,
    FACE_RESIZE_PERCENT,
    FIREBASE_CREDENTIALS_PATH,
    IMAGE_FOLDER_PATH,
    SOCKET_HOST,
    SOCKET_PORT,
    TRAIN_MODEL_PATH,
    UNKNOWN_ALERT_COOLDOWN_SEC,
    UNKNOWN_IMAGE_PATH,
    ensure_data_dirs,
)
from gpio_controller import GpioController


def init_firebase() -> None:
    if not FIREBASE_CREDENTIALS_PATH:
        print("FIREBASE_CREDENTIALS_PATH not set; FCM alerts disabled.")
        return
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)


def send_unknown_person_alert() -> None:
    if not FCM_DEVICE_TOKEN or not firebase_admin._apps:
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title="Danger",
            body="Have unknown user in home",
        ),
        token=FCM_DEVICE_TOKEN,
    )
    response = messaging.send(message)
    print("Successfully sent FCM message:", response)


def handle_send_image_and_name(client_socket: socket.socket) -> None:
    family_name = client_socket.recv(1024).decode().strip()
    print("Family name:", family_name)

    image_data = b""
    while True:
        chunk = client_socket.recv(4096)
        if not chunk:
            break
        image_data += chunk

    decoded_image_data = base64.b64decode(image_data)
    image_file_path = os.path.join(IMAGE_FOLDER_PATH, f"{family_name}.jpg")

    with open(image_file_path, "wb") as file:
        file.write(decoded_image_data)

    print("Image saved to", image_file_path)


def handle_train_data() -> None:
    encodings = []
    names = []

    for root, _, files in os.walk(IMAGE_FOLDER_PATH):
        print(files)
        for file in files:
            path = os.path.join(root, file)
            name = os.path.splitext(file)[0]
            person = cv2.imread(path)
            if person is None:
                print("Skipped unreadable image:", path)
                continue

            width = int(person.shape[1] * FACE_RESIZE_PERCENT / 100)
            height = int(person.shape[0] * FACE_RESIZE_PERCENT / 100)
            person = cv2.resize(person, (width, height))

            face_encodings = face_recognition.face_encodings(person)
            if not face_encodings:
                print("No face found in:", path)
                continue

            encodings.append(face_encodings[0])
            names.append(name)
            cv2.imshow("Picture", person)
            cv2.moveWindow("Picture", 0, 0)
            if cv2.waitKey(0) == ord("q"):
                cv2.destroyAllWindows()

    print(names)
    with open(TRAIN_MODEL_PATH, "wb") as file:
        pickle.dump(names, file)
        pickle.dump(encodings, file)

    print("Face recognition training complete.")


def handle_open_camera(client_socket: socket.socket, gpio: GpioController) -> None:
    with open(TRAIN_MODEL_PATH, "rb") as file:
        names = pickle.load(file)
        encodings = pickle.load(file)

    font = cv2.FONT_HERSHEY_SIMPLEX
    cam = cv2.VideoCapture(CAMERA_PIPELINE)
    last_unknown_time = 0.0

    try:
        while True:
            _, frame = cam.read()
            frame_small = cv2.resize(frame, (0, 0), fx=0.25, fy=0.25)
            frame_rgb = cv2.cvtColor(frame_small, cv2.COLOR_BGR2RGB)
            face_positions = face_recognition.face_locations(frame_rgb, model="CNN")
            all_encodings = face_recognition.face_encodings(frame_rgb, face_positions)

            for (top, right, bottom, left), face_encoding in zip(
                face_positions, all_encodings
            ):
                name = "Unknown Person"
                matches = face_recognition.compare_faces(encodings, face_encoding)
                if True in matches:
                    first_match_index = matches.index(True)
                    name = names[first_match_index]

                top *= 4
                right *= 4
                bottom *= 4
                left *= 4
                cv2.rectangle(frame, (left, top), (right, bottom), (0, 0, 255), 2)
                cv2.putText(frame, name, (left, top - 6), font, 0.75, (0, 0, 255), 2)

                if name != "Unknown Person":
                    continue

                gpio.on()
                time.sleep(1)
                gpio.off()

                current_time = time.time()
                if current_time - last_unknown_time <= UNKNOWN_ALERT_COOLDOWN_SEC:
                    continue

                last_unknown_time = current_time
                cv2.imwrite(UNKNOWN_IMAGE_PATH, frame)
                print("Image saved as", UNKNOWN_IMAGE_PATH)

                with open(UNKNOWN_IMAGE_PATH, "rb") as image_file:
                    image_data = image_file.read()

                if client_socket.fileno() != -1:
                    client_socket.sendall(image_data)
                    print("Image sent to client")

                send_unknown_person_alert()

            cv2.imshow("Picture", frame)
            cv2.moveWindow("Picture", 0, 0)
            if cv2.waitKey(1) == ord("q"):
                break
    finally:
        cam.release()
        cv2.destroyAllWindows()


def run_server() -> None:
    ensure_data_dirs()
    init_firebase()
    gpio = GpioController()

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((SOCKET_HOST, SOCKET_PORT))
    server_socket.listen(1)
    print(f"Waiting for connection on {SOCKET_HOST}:{SOCKET_PORT}...")

    try:
        while True:
            client_socket, client_address = server_socket.accept()
            print("Connected:", client_address)

            try:
                text_data = client_socket.recv(1024).decode().strip()
                print("Received command:", text_data)

                if text_data == "train data":
                    handle_train_data()
                elif text_data == "open camera":
                    handle_open_camera(client_socket, gpio)
                elif text_data == "send image and name":
                    handle_send_image_and_name(client_socket)
                else:
                    print("Unsupported command:", text_data)
            finally:
                client_socket.close()
    except KeyboardInterrupt:
        print("Stopping socket server...")
    finally:
        gpio.cleanup()
        server_socket.close()


if __name__ == "__main__":
    run_server()
