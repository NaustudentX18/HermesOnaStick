# M5Stick S3 — Hardware Reference

Target board for HermesOnaStick. Sources: the official M5Stack docs/schematic, the
Zephyr `m5stack_sticks3` board definition (runtime-verified), and the M5StickS3 store
listing. Pin numbers below are the **ESP32-S3 GPIO** numbers, not module pins.

## SoC and memory

- **ESP32-S3-PICO-1-N8R8** — dual-core Xtensa LX7 @ 240 MHz.
- 8 MB SPI flash, 8 MB **octal** PSRAM.
- Native USB Serial/JTAG available.

> The PSRAM is **octal** (`CONFIG_SPIRAM_MODE_OCT=y`), unlike most SDK boards which use
> quad PSRAM. Getting this wrong produces a boot loop.

## Display — ST7789P3, 135×240, SPI

| Signal | GPIO |
|---|---|
| MOSI | G39 |
| SCK | G40 |
| RS (DC) | G45 |
| CS | G41 |
| RST | G21 |
| Backlight | G38 |

- The P3 panel has a nonzero **column/row offset** (x≈52, y≈40 per the Zephyr driver);
  the port must apply these so the 135×240 image is centered.
- Backlight on G38 is shared with the addressable RGB LED region — treat carefully.

## Audio — ES8311 codec

- ES8311 mono codec + MEMS microphone + speaker amplifier.
- The SDK's `CodecAudio` (ES8311 path) applies; wire the I2S pins per the schematic.

## PMIC — M5PM1 (I²C 0x6e)

- Power-management companion: battery charging and switchable rails.
- **Not** AXP2101 (CoreS3) and **not** AXP192 (StickC Plus). A new driver is required.
- Exposes the LCD/audio/IR rail; the display rail must be up before panel init.

## Buttons

- KEY1 (middle): `G11`, active-low.
- KEY2 (right): `G12`, active-low.
- No touchscreen. Map KEY1 → Talk, KEY2 → Cancel (long-press Cancel = new session).

## IMU and other

- **BMI270** 6-axis IMU, I²C `0x68` (`G48`/`G47`).
- IR transmitter and receiver.
- 250 mAh LiPo, USB-C.

## Caveats to verify on hardware

1. **M5PM1 init sequence** — pin the M5Stack source revision and record it (licensing).
2. **Battery voltage** — confirm the ADC divider ratio; the StickC Plus2 used a ×2
   divider on G38, but the S3 uses M5PM1, so this must be re-derived.
3. **ST7789P3 offsets** — confirm x/y offset and inversion on the real panel.
4. **Rail sequencing** — display/audio/IR rails must be enabled before their drivers init.

## Status

Unverified on physical hardware. This port stays **experimental** until a physical
verification report is recorded (see `docs/PLAN.md` M4).
