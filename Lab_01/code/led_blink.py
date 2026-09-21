#!/usr/bin/env python3
"""
CM4 Lab 01 - Blink an external LED on the IO board's 40-pin header.

Circuit (BCM numbering - the GPIO number, not the pin number):
    GPIO17 (header pin 11) --[ 330 ohm ]-->|-- GND (header pin 9)
                                          LED  (long leg / anode toward the resistor)

Uses libgpiod (python3-libgpiod, v1.6 API on Ubuntu 22.04). RPi.GPIO is a
Raspberry Pi OS library and is not the right tool on Ubuntu.

USAGE
    python3 led_blink.py            # blink 10 times
    python3 led_blink.py 30 0.2     # blink 30 times, 0.2 s on / 0.2 s off
(If you get "Permission denied", run it with sudo - see the lab page.)
"""
import sys
import time

import gpiod

CHIP = "gpiochip0"   # the main BCM2711 GPIO controller on the CM4
LED_GPIO = 17        # BCM number -> header pin 11


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    period = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5

    chip = gpiod.Chip(CHIP)
    led = chip.get_line(LED_GPIO)
    led.request(consumer="led_blink", type=gpiod.LINE_REQ_DIR_OUT, default_vals=[0])

    print(f"Blinking GPIO{LED_GPIO} {count} times - Ctrl+C to stop")
    try:
        for i in range(count):
            led.set_value(1)
            print(f"  {i + 1:>3}  ON ", end="\r", flush=True)
            time.sleep(period)
            led.set_value(0)
            print(f"  {i + 1:>3}  OFF", end="\r", flush=True)
            time.sleep(period)
    except KeyboardInterrupt:
        pass
    finally:
        led.set_value(0)
        led.release()
        chip.close()
        print("\nLED off, GPIO released.")


if __name__ == "__main__":
    main()
