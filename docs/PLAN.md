# HermesOnaStick — Project Plan

**Goal:** a professional, fully-polished voice-assistant app that runs on the
M5Stack M5Stick S3 and talks to your own Hermes Agent, built as a board port of the
[Hermes Gadget SDK](https://github.com/Adolanium/hermes-gadget-sdk).

**Status:** M0–M3 complete (scaffold, simulator, board port, launcher variant);
M4 (physical validation) and M5 (final polish) remain. The firmware compiles and
the core unit tests pass; the port is **experimental** until verified on hardware.

---

## 0. What we're building and why the SDK

The Hermes Gadget SDK is the right base because it already solves the hard 80%:

- A portable C++17 device core (`hg::App`) — state machine, protocol, auth, pairing,
  push-to-talk, VAD, playback, UI rendering, actions, telemetry, console. **It never
  changes for a new board.**
- A Hermes-side plugin (`plugin/`) — WebSocket hub, adapter, `gadget_*` agent tools.
  **Hermes itself stays unchanged.**
- A desktop simulator that runs the same core, so UI work happens on the laptop.
- Over-the-air update with bootloader rollback.

A new board is therefore *drivers + configuration only* — the SDK calls this a
"port" (`docs/porting.md`). Our job is to produce a professional port for the
M5Stick S3, plus a launcher-compatible release variant, plus documentation and CI.

### The thin-device model (why the Stick can do this)

The device never runs STT/TTS/LLM. It captures audio, renders text and RGB565 pixels,
plays PCM, and runs declared actions. The 8 MB flash / 8 MB PSRAM / dual-core S3 in the
Stick is more than enough for that.

---

## 1. Hardware target — M5Stick S3 (not StickC Plus2)

Two boards share the "M5Stick" name. **This project targets the M5Stick S3**, the
ESP32-S3 stick. The older M5StickC Plus2 is an ESP32-PICO-V3-02 (plain ESP32, no S3)
and is *out of scope*.

| Property | M5Stick S3 |
|---|---|
| SoC | ESP32-S3-PICO-1-N8R8 — 8 MB flash, 8 MB **octal** PSRAM |
| Display | 1.14" ST7789**P3**, 135×240, SPI (MOSI G39, SCK G40, RS G45, CS G41, RST G21, BL G38) |
| Audio | ES8311 codec + MEMS mic + speaker amp |
| PMIC | **M5PM1** (I²C `0x6e`) — NOT AXP2101, NOT AXP192 |
| Buttons | KEY1 `G11`, KEY2 `G12` (active-low) |
| IMU | Bosch BMI270, I²C `0x68` (`G48`/`G47`) |
| Power | 250 mAh LiPo, USB-C |

Full pin map and caveats live in [HARDWARE.md](HARDWARE.md).

### Why this is a new port, not a recompile

The SDK ships seven boards; the M5Stick S3 is not among them. The closest is the
CoreS3, but the Stick differs materially:

- **PMIC is M5PM1, not AXP2101.** The `AxpPower` driver does not apply; we need a new
  M5PM1 driver (or a minimal latch-power fallback) for battery read and rail control.
- **Display is ST7789P3 at 135×240**, an SPI panel — unlike CoreS3's I80 ST7789 and its
  DLDO1 backlight routing. Offsets differ (x=52, y=40 for the P3 panel).
- **Buttons are two discrete GPIOs** (G11/G12), not a touchscreen — simpler input, but
  it changes the interaction labels (Talk/Cancel) and the UI hint bar.
- **No touchscreen**, so `TouchGestures` is not used; we map buttons directly to
  `hg::Button::Talk` / `hg::Button::Cancel`.

The good news: ST7789 SPI display and I2S mic/amp code paths *already exist* in the SDK
(`SpiDisplay`, `I2sMic`, `I2sSpeaker`), so the display and raw-audio wiring is mostly
configuration, not new drivers. The genuinely new work is the **M5PM1 PMIC driver** and
the **ST7789P3 offsets**.

---

## 2. Milestones

### M0 — Scaffold (done, this repo)
- [x] Repo created (`NaustudentX18/HermesOnaStick`), public, MIT.
- [x] README, LICENSE, .gitignore, .gitmodules, CI skeleton, this plan.

### M1 — Submodule + simulator profile ✅ done
- [x] SDK added as a submodule at `firmware/hermes-gadget-sdk`, pinned to the fork's
  `port/m5stick-s3` branch (commit carries the port).
- [x] `sim-m5stick-s3` profile added to the simulator (240×135 landscape, two buttons,
  no touch). Verified: board registers and boots in a headless smoke test.
- **Done when:** `hermes-gadget sim --board sim-m5stick-s3` renders at 240×135 and
  pushes button events. ✅ verified.

### M2 — Board port (the core engineering) ✅ done
Following `docs/porting.md`, added to the SDK tree:
1. [x] `Kconfig.projbuild`: `HG_BOARD_M5STICK_S3` choice.
2. [x] `board.cpp` / `board.hpp`: `BoardConfig` for the Stick (SPI ST7789P3, ES8311
   bidirectional codec, buttons G11/G12, M5PM1 power).
3. [x] `firmware/esp32/boards/m5stick-s3/sdkconfig.defaults`: target `esp32s3`, 8 MB flash,
   **octal PSRAM** (`CONFIG_SPIRAM_MODE_OCT=y`), `CONFIG_HG_BOARD_M5STICK_S3=y`.
4. [x] `boards/m5stick-s3/board.json`: installer title/summary, `ready_made: true`.
5. [x] New **M5PM1 driver** (`firmware/drivers/m5pm1.cpp/hpp`) implementing `Power`
   (VBAT via I2C 0x22/0x23, power source 0x04, keyed SYS_CMD shutdown), plus unit tests.
6. [x] ST7789P3 offset handling (x=52, y=40); mirror/invert set for landscape.
7. [x] Buttons wired to Talk/Cancel (`KEY1`/`KEY2` labels).
8. [x] `es8311_bidir` codec path: single ES8311 does mic ADC + speaker DAC.

**Done when:** `idf.py build` succeeds for `m5stick-s3`, the simulator matches, and the
board boots to the mascot "ready" screen on hardware. ✅ `idf.py build` succeeds
(`hermes_gadget.bin` 0x12d460, 39% slot free); the simulator matches; hardware boot
awaits M4.

### M3 — Launcher-compatible release ✅ done
- [x] `launcher/partitions.csv`: single `factory` app slot at 0x10000 (8 MB flash).
- [x] `launcher/build.sh` produces `HermesOnaStick-m5stick-s3-<version>.bin` (merged)
  and `-app.bin` (standalone), plus `SHA256SUMS`. ✅ built (0.2.0).
- [x] `docs/LAUNCHER.md` documents the load-via-M5Launcher steps and the SD pins.

> ⚠️ Still open (M4): M5Launcher's supported-device list and app-offset assumptions
> must be verified against the S3. Until then the documented USB/OTA fallback is the
> confirmed path. See [LAUNCHER.md](LAUNCHER.md).

**Done when:** a `.bin` release loads from M5Launcher and boots to the pairing screen.
✅ build done; physical M5Launcher load pending M4.

### M4 — Physical hardware validation
Per the SDK's `docs/hardware-validation.md`:
- Record a complete physical verification report for the exact board revision:
  display init/offsets, both buttons, mic capture, speaker playback, Wi-Fi, battery
  read, sleep/wake, OTA (or launcher) flash.
- Record voltage-divider ratios and signal polarity explicitly.
- Keep the port **experimental** until this report is linked.

**Done when:** the verification table links a passing report for `m5stick-s3`.

### M5 — Polish (the "fully polished" bar)
- **Face/artwork:** generate a custom face (`hermes-gadget face`) if desired, or keep
  the stock mascot; document the choice.
- **Device actions:** expose the Stick's LED and (optionally) buzzer as agent tools
  (`led.set`, `buzzer.beep`), following `docs/porting.md#device-actions`.
- **IMU/IR as sensors:** optional — expose BMI270 or IR as `app.set_sensor(...)`.
- **OTA:** confirm `hermes gadget update` works from a release (rollback safety).
- **Docs:** install guide, pairing guide, troubleshooting, CHANGELOG, SECURITY,
  CONTRIBUTING, THIRD_PARTY_NOTICES.
- **CI:** build matrix across boards, size checks, simulator tests, lint.

**Done when:** the project reads as a first-class, self-documenting, CI-green repo a
stranger can flash and pair in ten minutes.

---

## 3. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| M5PM1 PMIC driver is non-trivial | Blocks battery/power | Minimal latch-power fallback first; full M5PM1 later. Pin M5Stack source. |
| M5Launcher + dual-OTA collision | Launcher install fails | Separate launcher partition table; fallback to USB flash + OTA. |
| ST7789P3 offsets/init wrong | Blank or shifted screen | Simulator + physical test; record exact init from M5Stack source. |
| Octal PSRAM misconfig | Firmware won't boot | Correct `CONFIG_SPIRAM_MODE_OCT=y` from day one. |
| SDK drift | Port breaks on SDK update | Pin the submodule to a release tag; CI against pinned version. |

---

## 4. Toolchain prerequisites

- **ESP-IDF** v5.x (match the SDK's pinned version — check `firmware/esp32/idf_component.yml`
  and the SDK's CI). Install via `idf.py` toolchain or PlatformIO (the SDK ships a
  `platformio.ini`).
- **Python 3.10+** for the simulator and `hermes-gadget` CLI.
- **CMake 3.16+**, a C++17 compiler (for the simulator).
- **Hermes Agent + Gadget plugin** on the host, with STT and TTS configured (for real
  conversations; the simulator works standalone).

## 5. Definition of done (project-level)

- [ ] Board boots to the mascot "ready" screen on physical M5Stick S3 hardware.
- [ ] Hold-to-talk → Hermes STT → reply → TTS → speaker playback works end to end.
- [ ] Battery level and power-off behave correctly (or are honestly marked unsupported).
- [ ] A reproducible `.bin` loads via M5Launcher **or** the documented USB/OTA path.
- [ ] Physical verification report recorded and linked.
- [ ] CI green: build + size check + simulator tests.
- [ ] README, install, pairing, troubleshooting, licensing docs complete and accurate.
