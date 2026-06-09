#!/bin/bash
set -e

cd /mnt/d/SCTerminal
echo "PWD: $(pwd)"

HAP="entry/build/default/outputs/default/entry-default-unsigned.hap"
echo "HAP: $HAP"
echo "exists: $(test -f "$HAP" && echo yes || echo no)"

echo ""
echo "=== Before ==="
ls -lh "$HAP"

echo ""
echo "=== HNP dir ==="
ls entry/hnp/*/

echo ""
echo "=== Inject ==="
zip -r "$HAP" entry/hnp/

echo ""
echo "=== After ==="
ls -lh "$HAP"

echo ""
echo "=== Verify HNP inside ==="
unzip -l "$HAP" | grep -i "hnp" | head -10

echo ""
echo "=== Check module.json ==="
unzip -p "$HAP" module.json | python3 -c "import sys,json;d=json.load(sys.stdin);print('hnpPackages:',d['module'].get('hnpPackages','NONE'))"

echo ""
echo "=== Install ==="
"/mnt/d/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" app install "$HAP"

echo "Done"
