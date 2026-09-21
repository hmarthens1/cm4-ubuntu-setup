#!/usr/bin/env python3
"""
CM4 Lab 01 - Push-button controls the LED (GPIO input + output).

Circuit (BCM numbering):
    LED     GPIO17 (header pin 11) --[ 330 ohm ]-->|-- GND (header pin 9)
    Button  GPIO27 (header pin 13) --[ button ]-- GND (header pin 14)

No resistor is needed on the button: the CM4's internal pull-up holds GPIO27
at 1 (high) until the button connects it to GND, which reads as 0 (pressed).

USAGE
    python3 button_led.py           # Ctrl+C to stop
"""
import time

import gpiod

CHIP = "gpiochip0"
LED_GPIO = 17        # header pin 11
BUTTON_GPIO = 27     # header pin 13


def main():
    chip = gpiod.Chip(CHIP)
    led = chip.get_line(LED_GPIO)
    button = chip.get_line(BUTTON_GPIO)
    led.request(consumer="button_led", type=gpiod.LINE_REQ_DIR_OUT, default_vals=[0])
    button.request(consumer="button_led", type=gpiod.LINE_REQ_DIR_IN,
                   flags=gpiod.LINE_REQ_FLAG_BIAS_PULL_UP)

    print("Hold the button to light the LED - Ctrl+C to stop")
    presses = 0
    was_pressed = False
    try:
        while True:
            pressed = button.get_value() == 0   # pulled up: pressed reads 0
            led.set_value(1 if pressed else 0)
            if pressed and not was_pressed:
                presses += 1
                print(f"  pressed ({presses})")
            was_pressed = pressed
            time.sleep(0.02)                    # 20 ms poll also debounces
    except KeyboardInterrupt:
        pass
    finally:
        led.set_value(0)
        led.release()
        button.release()
        chip.close()
        print(f"\n{presses} presses. LED off, GPIO released.")


if __name__ == "__main__":
    main()
