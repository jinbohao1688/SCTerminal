#!/bin/bash
set -e

HAP=entry/build/default/outputs/default/entry-default-unsigned.hap
HDC="/mnt/d/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe"

echo "=== Step 1: Check HAP ==="
ls -lh "$HAP"

echo ""
echo "=== Step 2: Inject HNP ==="
zip -r "$HAP" entry/hnp/

echo ""
echo "=== Step 3: Verify size ==="
ls -lh "$HAP"

echo ""
echo "=== Step 4: Verify HNP inside ==="
unzip -l "$HAP" | grep -i "hnp" | head -10

echo ""
echo "=== Step 5: Install to device ==="
"$HDC" app install "$HAP"

echo ""
echo "=== Done ==="
