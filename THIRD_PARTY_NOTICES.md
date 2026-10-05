# Third-party notices and attribution

HermesOnaStick is a board port of the
[Hermes Gadget SDK](https://github.com/Adolanium/hermes-gadget-sdk) (MIT). The SDK
is vendored as a submodule at `firmware/hermes-gadget-sdk`; its own
`NOTICE`, `THIRD_PARTY_NOTICES.md`, and `LICENSES/` files apply to the vendored
portions and are preserved in that submodule.

## Directly adapted sources

The M5Stick S3 port reads register maps and initialization sequences from
M5Stack's own open-source drivers, referenced for pin/register accuracy rather
than vendored:

| Source | License | Used for |
|---|---|---|
| [M5PM1](https://github.com/m5stack/M5PM1) | MIT | M5PM1 register map (VBAT 0x22/0x23, PWR_SRC 0x04, SYS_CMD 0x0C) |
| [M5Unified](https://github.com/m5stack/M5Unified) | MIT | StickS3 pin map, ES8311 bidirectional init, PMIC GPIO3 amp-enable |
| M5Stack StickS3 docs/schematic | M5Stack documentation | Pin assignments for display, audio, buttons, SD |

No M5Stack source is copied verbatim into this repository; the driver code is
written against the register maps documented above, with the source revision
noted in `docs/HARDWARE.md` and the relevant source comments.

## Trademarks

"Hermes", "Hermes Agent", and "Nous Research" are trademarks of Nous Research.
"M5Stack", "M5Stick", and the M5 product names are trademarks of M5Stack. All
are used here only to describe compatibility and are not an endorsement.
