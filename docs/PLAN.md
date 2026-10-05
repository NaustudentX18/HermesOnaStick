# HermesOnaStick — Project Plan

**Goal:** a professional, fully-polished voice-assistant app that runs on the
M5Stack M5Stick S3 and talks to your own Hermes Agent, built as a board port of the
[Hermes Gadget SDK](https://github.com/Adolanium/hermes-gadget-sdk).

**Status:** greenfield. M0 (this scaffold) is done; M1–M5 are planned below.

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

### M1 — Submodule + simulator profile
- Add the SDK as a submodule at `firmware/hermes-gadget-sdk`, pinned to the v0.2.0 tag.
- Add a `m5stick-s3` profile to the simulator (`python/hermes_gadget/sim/runner.py`)
  with a 135×240 ST7789 SPI display, two buttons, no touch, ES8311 audio. This lets all
  UI work happen on the laptop before the board exists.
- **Done when:** `hermes-gadget sim --board m5stick-s3` renders the round/rect UI at
  135×240 and pushes button events.

### M2 — Board port (the core engineering)
Following `docs/porting.md`, add to the SDK tree:
1. `Kconfig.projbuild`: `HG_BOARD_M5STICK_S3` choice.
2. `board.cpp` / `board.hpp`: `BoardConfig` for the Stick (SPI ST7789P3, ES8311 codec
   or I2S mic, buttons G11/G12, M5PM1 power, status LED G38 if exposed).
3. `firmware/esp32/boards/m5stick-s3/sdkconfig.defaults`: target `esp32s3`, 8 MB flash,
   **octal PSRAM** (`CONFIG_SPIRAM_MODE_OCT=y`), `CONFIG_HG_BOARD_M5STICK_S3=y`.
4. `boards/m5stick-s3/board.json`: installer title/summary, `ready_made: true`.
5. New **M5PM1 driver** (`firmware/drivers/m5pm1.cpp/hpp`) implementing `Power`
   (battery voltage/percent via the ADC, charging state, `power_off`). Follow the
   AXP2101 driver as a template; pin the M5Stack source revision for the init sequence
   and record it for licensing.
6. ST7789P3 offset handling (x=52, y=40) so the 135×240 image is centered correctly.
7. Wire buttons to Talk/Cancel; set `talk_label` / `cancel_label`.
8. Simulator profile mirrors the real peripherals (already done in M1).

**Done when:** `idf.py build` succeeds for `m5stick-s3`, the simulator matches, and the
board boots to the mascot "ready" screen on hardware.

### M3 — Launcher-compatible release
The SDK's default `partitions.csv` is a two-slot OTA scheme with bootloader rollback.
M5Launcher installs a *single* app `.bin` into its own OTA slot from SD. These two
schemes collide, so we ship a **launcher variant**:

- A `launcher/partitions.csv` with a single `factory`/`ota_0` app slot sized to the
  Stick's 8 MB flash, matching what M5Launcher expects.
- A merged single `.bin` (bootloader + partition table + app) built for that table,
  named `HermesOnaStick-m5stick-s3-<version>.bin`.
- A `launcher/build.sh` (or PlatformIO env) that produces this artifact reproducibly.
- A `launcher/README.md` documenting the exact "load via M5Launcher" steps.

> ⚠️ Known risk: M5Launcher's supported-device list and app-offset assumptions must be
> verified against the M5Stick S3 before this is marked done. If M5Launcher does not
> cleanly host the S3, the fallback is the SDK's standard USB flash + OTA path (which
> always works). See [LAUNCHER.md](LAUNCHER.md).

**Done when:** a `.bin` release loads from M5Launcher and boots to the pairing screen
(and, failing that, the documented USB/OTA path is verified and the launcher limitation
is stated honestly).

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
