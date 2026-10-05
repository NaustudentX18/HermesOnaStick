# M5Launcher — Loading HermesOnaStick

M5Launcher ([bmorcelli/Launcher](https://github.com/bmorcelli/Launcher)) boots a
launcher firmware and installs app `.bin` files from an SD card into an OTA partition.
This page documents how HermesOnaStick fits — and where it doesn't yet.

## The collision

The Hermes Gadget SDK ships a **dual-slot OTA** partition table with bootloader
rollback (two ~1.9 MB `ota_0`/`ota_1` slots). M5Launcher, by contrast, installs a
**single** app image into its own fixed app slot and handles switching in its own
bootloader. Flash a stock SDK `.bin` straight into M5Launcher and the partition maps
will not line up — the app won't start.

## The plan: a launcher-compatible variant

HermesOnaStick ships a second build variant alongside the stock OTA firmware:

1. `launcher/partitions.csv` — a single `factory`/`ota_0` app slot sized for the
   8 MB flash, no dual-OTA.
2. A merged `HermesOnaStick-m5stick-s3-<version>.bin` (bootloader + partition table +
   app) built against that table.
3. `launcher/build.sh` produces the artifact reproducibly (idf.py or PlatformIO).
4. Load it via M5Launcher per the launcher's own workflow (place `.bin` on SD, select
   it, install).

## Open questions (blocking M3)

- **Does M5Launcher support the M5Stick S3?** The launcher's supported-device list and
  app-offset assumptions must be confirmed against the S3. The S3 is new enough that the
  launcher may need a config entry.
- **App offset** — the launcher lets a firmware sit at a non-default app address; the
  exact offset for the S3 must be captured and encoded in the variant.

## Fallback (always works)

Even if M5Launcher support is incomplete, the **standard path always works** and is the
primary documented route:

```bash
idf.py -p /dev/cu.usbmodem* flash monitor     # USB flash
hermes gadget update                           # subsequent OTA updates
```

M5Launcher is a convenience for hot-swapping between many apps; for a single
dedicated device, USB + OTA is the cleaner, more reliable path.

## Status

M3 (launcher variant) is **not yet implemented**. Until it is, do not assume a stock
`.bin` will load from M5Launcher — use USB flash. This file will be updated with exact
steps once the variant builds and is verified on hardware.
