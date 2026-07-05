"""Optional GPIO controller for Jetson Nano LED alerts."""

from config import GPIO_LED_PIN


class GpioController:
    def __init__(self) -> None:
        self._gpio = None
        self._pin = GPIO_LED_PIN
        self._available = False
        self._setup()

    def _setup(self) -> None:
        try:
            import Jetson.GPIO as GPIO  # type: ignore

            self._gpio = GPIO
            GPIO.setwarnings(False)
            GPIO.setmode(GPIO.BOARD)
            GPIO.setup(self._pin, GPIO.OUT)
            self._available = True
        except Exception as exc:
            print(f"GPIO unavailable, LED alerts disabled: {exc}")

    def on(self) -> None:
        if self._available and self._gpio is not None:
            self._gpio.output(self._pin, self._gpio.HIGH)

    def off(self) -> None:
        if self._available and self._gpio is not None:
            self._gpio.output(self._pin, self._gpio.LOW)

    def cleanup(self) -> None:
        if self._available and self._gpio is not None:
            self._gpio.cleanup()
