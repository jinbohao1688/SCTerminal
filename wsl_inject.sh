#!/bin/bash
set -e

cd /mnt/d/SCTerminal
HAP=entry/build/default/outputs/default/entry-default-unsigned.hap

echo "=== Step 1: Check HAP ==="
ls -lh "$HAP"

echo ""
echo "=== Step 2: Clean old HNP entries ==="
# Remove existing hnp entries to avoid duplicates
mkdir -p /tmp/hap_work
cd /tmp/hap_work
unzip -o "/mnt/d/SCTerminal/$HAP" -d hap_content 2>&1 | tail -5
rm -rf hap_content/entry/hnp
# Rebuild zip without hnp entries
cd hap_content
zip -r "/mnt/d/SCTerminal/$HAP" . 2>&1 | tail -5
cd /tmp/hap_work
rm -rf hap_content

echo ""
echo "=== Step 3: Inject HNP ==="
cd /mnt/d/SCTerminal
zip -r "$HAP" entry/hnp/

echo ""
echo "=== Step 4: Verify ==="
ls -lh "$HAP"
echo ""
unzip -l "$HAP" | grep -i "hnp" | head -10

echo ""
echo "=== Step 5: Install to device ==="
hdc app install "$HAP"

echo ""
echo "=== Done ==="
