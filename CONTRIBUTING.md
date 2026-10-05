# Contributing

Bug reports from real boards, fixes, and documentation improvements are welcome.

## Before you start

- The firmware is a **port** of the [Hermes Gadget
  SDK](https://github.com/NaustudentX18/hermes-gadget-sdk) (forked, on the
  `port/m5stick-s3` branch). Board-port changes live there; this repository holds
  the port glue, launcher variant, docs, and CI.
- Read the SDK's `docs/porting.md` and `docs/hardware-validation.md` — they define
  how a board is added and what "verified" means.
- Sweep open issues before opening a new one.

## Adding a board / changing the port

1. Make the change in the SDK submodule on a branch off `port/m5stick-s3`.
2. Add a simulator profile matching the hardware in `python/hermes_gadget/sim/runner.py`.
3. Build with `idf.py` (see `docs/PLAN.md` §4) and confirm the image fits its slot.
4. Update `docs/HARDWARE.md`, `docs/PLAN.md`, and the changelog.
5. If you touched shared SDK code, require the full board matrix to build.

## Physical verification

A board port is experimental until a physical report is recorded. Use
`docs/HARDWARE_VALIDATION.md` as the checklist and record the exact board
revision, firmware version, and pass/fail per item.

## Style

- Follow the surrounding C++17 style (no exceptions/RTTI, `hg::` core untouched).
- Match the SDK's MIT headers and attribution practice.
- One logical change per commit; descriptive commit messages.

## License

Project code is MIT (see `LICENSE`). The vendored SDK and its third-party
notices are preserved in the submodule — do not strip attribution.
