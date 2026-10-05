# Changelog

All notable changes to HermesOnaStick are documented here. The project uses
[Semantic Versioning](https://semver.org/); the version tracks the Hermes Gadget
SDK release it builds against (currently 0.2.0).

## [Unreleased]

### Added
- M0: repository scaffold — README, plan, hardware reference, launcher notes, CI.
- M1: `sim-m5stick-s3` simulator profile (240×135, two buttons, no touch).
- M2: full M5Stick S3 board port (ST7789P3 display, KEY1/KEY2 buttons, M5PM1
  power driver, ES8311 bidirectional audio, octal-PSRAM config).
- M3: launcher-compatible partition table and build script producing a single-app
  `.bin` for M5Launcher, plus the standalone `-app.bin`.

### Status
- The port is **experimental** until a physical verification report is recorded
  (see `docs/HARDWARE_VALIDATION.md`).

## [0.1.0] - Initial scaffold
- Initial repository and planning documents.
