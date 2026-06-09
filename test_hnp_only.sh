#!/bin/bash
set -e

cd /mnt/d/SCTerminal
HAP="entry/build/default/outputs/default/entry-default-unsigned.hap"
HDC="/mnt/d/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe"

echo "HAP path: $HAP"
ls -lh "$HAP"

echo ""
echo "=== Inject HNP files ==="
zip -r "$HAP" entry/hnp/

echo ""
echo "=== After injection ==="
ls -lh "$HAP"

echo ""
echo "=== Verify no hnpPackages ==="
unzip -p "$HAP" module.json | python3 -c 'import sys,json;d=json.load(sys.stdin);print("hnpPackages:", d["module"].get("hnpPackages","NOT PRESENT"))'

echo ""
echo "=== HNP files in HAP ==="
unzip -l "$HAP" | grep -i "hnp"

echo ""
echo "=== Install ==="
"$HDC" app install "$HAP"
