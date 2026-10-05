# M5Stick S3 — Hardware Reference

Target board for HermesOnaStick. Sources: the official M5Stack StickS3 docs and
schematic, M5Stack's M5Unified/M5PM1/M5GFX source, and the runtime-verified
Zephyr `m5stack_sticks3` board definition. Pin numbers are **ESP32-S3 GPIO**
numbers, not module pins.

## SoC and memory

- **ESP32-S3-PICO-1-N8R8** — dual-core Xtensa LX7 @ 240 MHz.
- 8 MB SPI flash, 8 MB **octal** PSRAM.
- Native USB Serial/JTAG.

> PSRAM is **octal** (`CONFIG_SPIRAM_MODE_OCT=y`), unlike most SDK boards which
> use quad PSRAM. Getting this wrong produces a boot loop.

## Display — ST7789P3, 135×240 (portrait) → 240×135 (landscape), SPI

| Signal | GPIO |
|---|---|
| MOSI | G39 |
| SCK | G40 |
| RS (DC) | G45 |
| CS | G41 |
| RST | G21 |
| Backlight | G38 |

- The port swaps the panel to landscape (`swap_xy`) so the 240×135 framebuffer
  matches the SDK's wide UI.
- The P3 panel has a nonzero column/row offset (x≈52, y≈40 per the Zephyr
  driver); the port applies `gap_x=52`, `gap_y=40`. **These, plus mirror/invert,
  need physical confirmation (M4).**

## Audio — ES8311 codec (bidirectional)

- A **single ES8311** (I²C `0x18`) does both the microphone ADC and the speaker
  DAC on one duplex I2S bus — the Stick has **no separate ES7210**.
- I2S pins (from the StickS3 schematic / M5Unified `_speaker_enabled_cb_sticks3`):

| Signal | GPIO |
|---|---|
| MCLK | G18 |
| BCLK | G17 |
| LRCK (WS) | G15 |
| DOUT (codec→S3, mic) | G14 |
| DIN (S3→codec, speaker) | G16 |

- Speaker amplifier enable is **M5PM1 GPIO3** (bit 3 of PMIC reg 0x11), not a
  direct GPIO — handled by the M5PM1 power companion, not the ES8311 `pa_pin`.

## Buttons

- KEY1 (middle): `G11`, active-low → **Talk**.
- KEY2 (right): `G12`, active-low → **Cancel** (hold 2 s = new session).
- No touchscreen.

## PMIC — M5PM1 (I²C 0x6E)

- M5Stack's PM1 power-management companion (a PY32-based PMIC). **Not** AXP2101
  (CoreS3) and **not** AXP192 (StickC Plus).
- The port's `M5Pm1` driver reads:
  - power source from `PWR_SRC` (0x04): 0=none, 1=USB/5VIN, 3=battery;
  - battery voltage from `VBAT` (0x22/0x23), in mV.
- Shutdown is the keyed `SYS_CMD` (0x0C): `0xA1` = key 0xA | shutdown 0x01.
- Internal I²C bus: SDA=G47, SCL=G48 (carries BMI270, M5PM1, ES8311).
- **Charging state is not exposed** by the register range the driver reads; the
  port leaves `charging` unset rather than guess.

## IMU and SD

- **BMI270** 6-axis IMU, I²C `0x68` (shared internal bus).
- **SD card** (optional, user-added module on the Hat2-Bus header): CS=G5,
  MOSI=G4, SCK=G6, MISO=G7. Used only by the M5Launcher variant (M3); the
  firmware itself uses NVS + OTA, not SD. No conflict with the display pins.

## Caveats to verify on hardware (see docs/HARDWARE_VALIDATION.md)

1. **ST7789P3 offsets + mirror/invert** — confirm x/y offset and orientation on
   the real panel.
2. **M5PM1 battery voltage** — confirm the VBAT register reads correctly in mV.
3. **ES8311 bidirectional capture+playback** — confirm mic and speaker coexist
   on the single codec.
4. **Rail sequencing** — the M5PM1 boots its LCD/audio rails; confirm the panel
   and codec come up before their drivers init.

## Status

Unverified on physical hardware. The port is **experimental** until
`docs/HARDWARE_VALIDATION.md` records a passing physical report.
