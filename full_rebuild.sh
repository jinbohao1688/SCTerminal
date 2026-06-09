#!/bin/bash
set -e

cd /mnt/d/SCTerminal

BASE_HAP=entry/build/default/outputs/default/entry-default-unsigned.hap
WORK_DIR=/tmp/hap_rebuild_$$
OUT_HAP=entry/build/default/outputs/default/entry-default-rebuilt.hap

echo "=== Starting fresh rebuild ==="

# Clean work dir
rm -rf $WORK_DIR
mkdir -p $WORK_DIR/content

# Extract base HAP
cd $WORK_DIR/content
unzip -o "/mnt/d/SCTerminal/$BASE_HAP" 2>&1 | tail -3
cd $WORK_DIR

echo ""
echo "=== Current module.json hnpPackages ==="
grep -A5 '"hnpPackages"' content/module.json 2>/dev/null || echo "  No hnpPackages"

# Add hnpPackages to module.json if missing
python3 << 'PYEOF'
import json
with open('content/module.json', 'r') as f:
    data = json.load(f)
if 'hnpPackages' not in data['module']:
    data['module']['hnpPackages'] = [{"package": "sct-tools", "type": "private"}]
    with open('content/module.json', 'w') as f:
        json.dump(data, f)
    print("Added hnpPackages to module.json")
else:
    print("hnpPackages already present:", data['module']['hnpPackages'])
PYEOF

# Copy HNP files
echo ""
echo "=== Adding HNP files ==="
mkdir -p content/entry/hnp
cp -r /mnt/d/SCTerminal/entry/hnp/arm64-v8a content/entry/hnp/
cp -r /mnt/d/SCTerminal/entry/hnp/x86_64 content/entry/hnp/
ls -lh content/entry/hnp/*/

# Recreate HAP
echo ""
echo "=== Creating new HAP ==="
cd content
zip -r "/mnt/d/SCTerminal/$OUT_HAP" . 2>&1 | tail -5
cd /mnt/d/SCTerminal
ls -lh "$OUT_HAP"

# Verify
echo ""
echo "=== Verification ==="
unzip -l "$OUT_HAP" | grep -i "hnp" | head -10

echo ""
echo "=== Install ==="
"/mnt/d/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe" app install "$OUT_HAP"

echo ""
echo "=== Done ==="
rm -rf $WORK_DIR
