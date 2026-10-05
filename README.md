<p align="center">
  <img src="https://avatars.githubusercontent.com/u/94890352?v=4" width="80" alt="HermesOnaStick" style="border-radius:50%">
</p>

<h1 align="center">HermesOnaStick</h1>

<p align="center">
  <b>Hold a button. Ask Hermes. Hear the answer.</b><br>
  A pocketable voice assistant for your own <a href="https://github.com/NousResearch/hermes-agent">Hermes Agent</a>,<br>
  built on the <a href="https://github.com/Adolanium/hermes-gadget-sdk">Hermes Gadget SDK</a> and sized for the
  <a href="https://docs.m5stack.com/en/core/M5Stick%20S3">M5Stack M5Stick S3</a>.
</p>

<p align="center">
  <a href="#quick-start"><b>Flash it</b></a> ·
  <a href="docs/PLAN.md"><b>Read the plan</b></a> ·
  <a href="docs/LAUNCHER.md"><b>M5Launcher notes</b></a> ·
  <a href="docs/HARDWARE.md"><b>Board reference</b></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-ESP32--S3-blue" alt="ESP32-S3">
  <img src="https://img.shields.io/badge/framework-ESP--IDF-green" alt="ESP-IDF">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT">
  <img src="https://github.com/NaustudentX18/HermesOnaStick/actions/workflows/ci.yml/badge.svg" alt="CI">
</p>

---

## What it is

HermesOnaStick turns the M5Stick S3 into a thin, pocketable voice terminal for your
Hermes Agent. All the thinking happens on your Hermes host — speech recognition,
text-to-speech, the language model, your tools, memory and skills. The Stick only
captures audio, renders text and pixels, plays back PCM, and runs the device actions
you declare.

This project is a **board port** of the
[Hermes Gadget SDK](https://github.com/Adolanium/hermes-gadget-sdk). The portable C++17
device core is inherited unchanged; this repository adds the M5Stick S3 drivers,
board configuration, a launcher-compatible build variant, and the documentation to
keep it professional.

> ⚠️ **Status: greenfield / pre-hardware-validation.** The M5Stick S3 is *not* one of
> the SDK's seven shipped boards. This repo is the port that makes it one. Until a
> physical verification report is recorded for this exact board revision, the port is
> **experimental**. See [docs/PLAN.md](docs/PLAN.md).

## The hardware

| | M5Stick S3 |
|---|---|
| SoC | ESP32-S3-PICO-1-N8R8 (8 MB flash, 8 MB octal PSRAM) |
| Display | 1.14" ST7789P3 TFT, 135×240 |
| Audio | ES8311 codec, MEMS mic, speaker amplifier |
| PMIC | M5PM1 (I²C `0x6e`) — **not** AXP2101 |
| Input | Two buttons (KEY1 `G11`, KEY2 `G12`, active-low) |
| IMU | Bosch BMI270 (I²C `0x68`, `G48`/`G47`) |
| Power | 250 mAh LiPo, USB-C |

Full pin map and caveats: [docs/HARDWARE.md](docs/HARDWARE.md).

## Quick start

> No firmware toolchain yet? Read [docs/PLAN.md](docs/PLAN.md) for the full path, or
> start with the SDK's own [browser installer](https://adolanium.github.io/hermes-gadget-sdk/installer.html)
> to understand the pairing flow on a supported board first.

```bash
# 1. Clone with the SDK submodule
git clone --recurse-submodules https://github.com/NaustudentX18/HermesOnaStick.git
cd HermesOnaStick

# 2. Build the M5Stick S3 firmware (needs ESP-IDF, see docs/PLAN.md)
idf.py set-target esp32s3
idf.py -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;boards/m5stick-s3/sdkconfig.defaults" build

# 3. Flash over USB
idf.py -p /dev/cu.usbmodem* flash monitor
```

Once flashed, hold the button, speak, and release to send. Pair it with your Hermes
using the pairing code shown on screen (`hermes gadget` on the host). See the SDK's
[Connect Hermes](https://github.com/Adolanium/hermes-gadget-sdk/blob/main/docs/connect-hermes.md)
guide for the full host setup.

## Repository layout

```
HermesOnaStick/
├── firmware/            # SDK submodule (the M5Stick S3 port lives on its port/m5stick-s3 branch)
├── launcher/            # M5Launcher-compatible partition table + build script
├── docs/                # plan, hardware reference, validation checklist, launcher notes
├── .github/workflows/   # CI (scaffold sanity + host core unit tests)
└── CHANGELOG / CONTRIBUTING / SECURITY / THIRD_PARTY_NOTICES
```

## Project status

| Milestone | State |
|---|---|
| M0 — Repo scaffold, plan, CI skeleton | ✅ this repo |
| M1 — SDK submodule + simulator profile | ✅ |
| M2 — M5Stick S3 board port (display/buttons/PMIC/audio) | ✅ builds; unverified on HW |
| M3 — Launcher-compatible `.bin` release | ✅ builds; unverified on HW |
| M4 — Physical hardware validation | ⬜ pending board |
| M5 — Polish: face, actions, OTA, docs | ⬜ |

The firmware compiles and the core unit tests pass (62 cases, 0 failed); the port is
**experimental** until M4 records a physical verification report.

Tracked in full in [docs/PLAN.md](docs/PLAN.md).

## License and affiliation

Project code and documentation are licensed under the [MIT license](LICENSE).
The Hermes Gadget SDK it builds on is MIT-licensed; see its
[NOTICE](https://github.com/Adolanium/hermes-gadget-sdk/blob/main/NOTICE) for third-party
attribution that carries into this port.

HermesOnaStick is an **independent, community-made project**. It is not affiliated with,
endorsed by, or supported by Nous Research or M5Stack. "Hermes", "Hermes Agent" and "Nous
Research" are trademarks of Nous Research, used here only to describe compatibility.
