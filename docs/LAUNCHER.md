# M5Launcher — Loading HermesOnaStick

M5Launcher ([bmorcelli/Launcher](https://github.com/bmorcelli/Launcher)) boots a
launcher firmware and installs app `.bin` files from an SD card into an OTA
partition. HermesOnaStick ships a **launcher-compatible variant** for this.

## The collision (and how we resolve it)

The Hermes Gadget SDK's stock firmware uses a **dual-slot OTA** partition table
(two ~1.9 MB `ota_0`/`ota_1` slots with bootloader rollback). M5Launcher installs
a **single** app image into one app slot and does its own switching. Flash a
stock dual-OTA `.bin` into M5Launcher and the partition maps won't line up.

HermesOnaStick therefore builds a second variant against
[`launcher/partitions.csv`](../launcher/partitions.csv), which replaces the two
OTA slots with a single `factory` app slot at the conventional `0x10000` offset.

## Building the launcher variant

```bash
# needs ESP-IDF 5.3+ and the submodule checked out (see docs/PLAN.md §4)
env -u VIRTUAL_ENV bash launcher/build.sh
```

Outputs in `launcher/dist/`:

| File | What it is |
|---|---|
| `HermesOnaStick-m5stick-s3-<version>.bin` | merged bootloader + partition table + app (flash at 0x0) |
| `HermesOnaStick-m5stick-s3-<version>-app.bin` | the app image alone (the SD file M5Launcher installs) |
| `SHA256SUMS` | checksums |

## Loading via M5Launcher

1. Flash M5Launcher to the M5Stick S3 (per the launcher's own instructions for
   the Stick S3 — confirm the launcher lists the S3; see *Open questions*).
2. Copy `HermesOnaStick-m5stick-s3-<version>-app.bin` onto the SD card
   (your SD module is on Hat2-Bus: CS=G5, MOSI=G4, SCK=G6, MISO=G7).
3. Insert the SD, boot into M5Launcher, select the `.bin`, and install.

## Open questions

- **Does M5Launcher list the M5Stick S3?** The launcher's supported-device list
  and app-offset assumptions must be confirmed against the S3. If the launcher
  lacks an S3 entry, its config may need one.
- **App offset** — this variant places the app at `0x10000` (the `factory`
  slot), matching the launcher's conventional app address. Confirm the exact
  offset the launcher expects for the S3.

## Fallback (always works)

The standard path always works and is the primary documented route:

```bash
idf.py -p /dev/cu.usbmodem* flash monitor     # USB flash (full image at 0x0)
hermes gadget update                           # subsequent OTA updates
```

M5Launcher is a convenience for hot-swapping apps; for a single dedicated
device, USB + OTA is cleaner and more reliable.

## Status

- **M3 done:** the launcher variant builds (`launcher/build.sh` produces both
  images). **Not yet verified on hardware** — the S3's M5Launcher support and the
  exact app offset still need physical confirmation (M4).
