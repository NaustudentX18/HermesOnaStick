#!/bin/bash
# Build the HermesOnaStick M5Stick S3 launcher variant: a single-app image that
# M5Launcher can install from SD, plus the merged full-flash image.
#
# The launcher variant differs from the stock OTA firmware in one way: it uses
# launcher/partitions.csv (a single "factory" app slot at 0x10000) instead of the
# stock dual-OTA table, so the app lands where M5Launcher's SD updater expects it.
#
# Outputs (in launcher/dist/):
#   HermesOnaStick-m5stick-s3-<version>.bin       merged bootloader+table+app (0x0)
#   HermesOnaStick-m5stick-s3-<version>-app.bin    the app alone (for OTA/updater)
#   SHA256SUMS
#
# Run: env -u VIRTUAL_ENV bash /Volumes/AI1TB/dev/HermesOnaStick/launcher/build.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$HERE/../firmware"                 # the HermesOnaStick firmware tree
SDK="$FW/hermes-gadget-sdk"            # the SDK submodule
ESP32="$SDK/firmware/esp32"
IDF=/Volumes/AI1TB/toolchains/esp-idf
ENVPY=$(ls -d /Users/forest/.espressif/python_env/idf5.3_py3*/bin/python 2>/dev/null | head -1)
OUT="$HERE/dist"

unset VIRTUAL_ENV VIRTUAL_ENV_PROMPT
export IDF_PATH="$IDF"
export IDF_PYTHON_ENV_PATH="$(dirname "$(dirname "$ENVPY")")"
export PATH="$(dirname "$ENVPY"):$PATH"
. "$IDF/export.sh" >/dev/null 2>&1

# Build with the launcher partition table instead of the stock one.
cd "$ESP32"
"$ENVPY" "$IDF/tools/idf.py" \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;boards/m5stick-s3/sdkconfig.defaults" \
  -D CONFIG_PARTITION_TABLE_CUSTOM_FILENAME="$HERE/partitions.csv" \
  set-target esp32s3 build >/dev/null 2>&1

# Assemble the merged image with esptool, then the standalone app.
VERSION=$("$ENVPY" - <<'PY'
import re
from pathlib import Path
import sys
sys.path.insert(0, str(Path("build")))
# read version from the app image's esp_app_desc (offset 48..80 is version string)
app = Path("build/hermes_gadget.bin").read_bytes()
print(app[48:80].split(b"\0",1)[0].decode())
PY
)

mkdir -p "$OUT"
python3 "$IDF/components/esptool_py/esptool/esptool.py" --chip esp32s3 \
  merge_bin --output "$OUT/HermesOnaStick-m5stick-s3-$VERSION.bin" \
  --flash_mode dio --flash_size 8MB --flash_freq 80m \
  0x0 build/bootloader/bootloader.bin \
  0x8000 build/partition_table/partition-table.bin \
  0x10000 build/hermes_gadget.bin

cp build/hermes_gadget.bin "$OUT/HermesOnaStick-m5stick-s3-$VERSION-app.bin"

(cd "$OUT" && shasum -a 256 HermesOnaStick-m5stick-s3-*.bin > SHA256SUMS)

echo "launcher variant built in $OUT"
ls -la "$OUT"
