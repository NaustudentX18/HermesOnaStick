# M5Stick S3 — reference BoardConfig for the M2 port.

The `port/` tree holds reference files ready to drop into the SDK submodule once it is
added (M1). This file sketches the `board.cpp` `BoardConfig make()` for the Stick, so the
pin decisions are recorded up front and reviewed before any driver code is written.

## BoardConfig sketch

```cpp
#elif CONFIG_HG_BOARD_M5STICK_S3
BoardConfig make() {
  BoardConfig b{};
  b.name = kBoardName;                    // "m5stick-s3"
  b.m5pm1 = true;                         // NEW: M5PM1 PMIC (not AXP2101/AXP192)
  b.i2c = { /* SDA G8?, SCL G9? */ -1, -1, 400000 };  // confirm I2C pins from schematic

  // Display: SPI ST7789P3, 135x240 (after rotation), nonzero panel offsets.
  b.lcd.enabled = true;
  b.lcd.controller = LcdController::St7789;
  b.lcd.width  = 135;
  b.lcd.height = 240;
  b.lcd.swap_xy = true;                   // portrait -> landscape as the UI expects
  b.lcd.mirror_x = true;
  b.lcd.mirror_y = false;
  b.lcd.invert = true;
  b.lcd.gap_x = 52;                       // ST7789P3 column offset
  b.lcd.gap_y = 40;                       // ST7789P3 row offset
  b.lcd.mosi = 39; b.lcd.sclk = 40; b.lcd.cs = 41;
  b.lcd.dc = 45;  b.lcd.rst = 21; b.lcd.backlight = 38;

  // Audio: ES8311 codec + MEMS mic + amp (I2S pins TBD from schematic).
  b.codec.enabled = true;
  b.codec.speaker = SpeakerCodec::Es8311;
  b.codec = { true, /*mclk*/ -1, /*bclk*/ -1, /*ws*/ -1, /*dout*/ -1, /*din*/ -1 };

  // Inputs: two discrete buttons, no touchscreen.
  b.buttons = { /*talk*/ 11, /*cancel*/ 12, -1, -1 };  // KEY1=G11, KEY2=G12 (active-low)
  b.talk_label   = "KEY1";
  b.cancel_label = "KEY2";

  return b;
}
```

## Notes

- **I2C pins, codec I2S pins, and M5PM1 register map** must be read from the official
  M5Stick S3 schematic before this compiles. The placeholders above are marked with `TBD`.
- The M5PM1 driver is new work (see `docs/PLAN.md` M2) and is the main engineering risk.
- The simulator profile (M1) must mirror these choices so desktop UI work stays honest.
