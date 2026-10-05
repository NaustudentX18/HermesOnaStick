# Hardware Validation — M5Stick S3

The port stays **experimental** until a complete physical verification report is
recorded for this exact board revision. This checklist is the record; each item
must be checked on real hardware, not the simulator.

## Board under test

| Field | Value |
|---|---|
| Board | M5Stack M5Stick S3 |
| SoC | ESP32-S3-PICO-1-N8R8 (8 MB flash, 8 MB octal PSRAM) |
| Firmware | `HermesOnaStick-m5stick-s3-<version>.bin` |
| Date / tester | _(fill in)_ |

## Flash and boot

- [ ] USB flash succeeds (esptool, chip esp32s3, 8 MB, dio, 80 MHz).
- [ ] Device boots to the mascot "ready" screen (no panic, no boot loop).
- [ ] PSRAM initializes in octal mode (no `no PSRAM found` in the boot log).
- [ ] Serial console over USB Serial/JTAG responds (`diag`, `status`).

## Display (ST7789P3, 135×240 → 240×135 landscape)

- [ ] Screen is centered — no clipping at the edges (offsets x=52/y=40 correct).
- [ ] Orientation is correct (landscape, not upside-down or mirrored).
- [ ] Colors are correct (not inverted — dark background, light text).
- [ ] Backlight dims to off via `screen.brightness` / the screen-timeout setting.

> If any of the above fail, the mirror/invert/swap/offset values in
> `board.cpp` (`HG_BOARD_M5STICK_S3`) are the first thing to adjust.

## Buttons

- [ ] KEY1 (G11) = Talk: hold to speak, release to send; tap is discarded.
- [ ] KEY2 (G12) = Cancel: cancels recording, dismisses overlays, `/stop` on hold.
- [ ] Hold KEY2 for 2 s starts a new session (countdown shown in the hint bar).

## Audio (ES8311 bidirectional codec)

- [ ] Microphone captures: hold Talk, speak, and the audio reaches Hermes STT.
- [ ] Speaker plays: TTS reply is audible, no clipping/underruns.
- [ ] Barge-in works: pressing Talk during playback stops the reply immediately.
- [ ] Volume control (`speaker.volume`) changes playback level.

> The Stick's ES8311 does both mic ADC and speaker DAC on one I2S bus (no
> separate ES7210). If capture and playback don't coexist, the `es8311_bidir`
> path in `port_codec.cpp` is the suspect.

## Power (M5PM1 at I²C 0x6E)

- [ ] Battery voltage reads plausibly (3000–4200 mV on a charged cell).
- [ ] Power source reports USB vs battery correctly.
- [ ] `power_off` from the settings menu shuts the device down (keyed SYS_CMD).

> Charging state is **not** reported by this port (the M5PM1 status-register
> range used here doesn't expose it). Mark it unsupported rather than guess.

## Wi-Fi and pairing

- [ ] Wi-Fi joins and the device connects to the Hermes host.
- [ ] Pairing code appears on screen and `hermes gadget` approves it.
- [ ] A full hold-to-talk → STT → reply → TTS round-trip completes.

## OTA / launcher

- [ ] `hermes gadget update` installs the `-app.bin` and boots on probation.
- [ ] The update confirms (rollback safety) once it reaches Hermes.
- [ ] _(M3)_ The launcher `.bin` installs via M5Launcher from SD and boots.

## Record

Once every item above is checked (or explicitly marked N/A with a reason), fill
in the tester/date, record pass/fail per item, and note any firmware/board
revision that differs from the table. Link this completed report from
`docs/PLAN.md` M4 and the SDK's `docs/hardware-validation.md` so the port can be
promoted from experimental.
