import zipfile
import json
import os
import shutil

hap_path = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'

# Read the base HAP (no HNP, no hnpPackages - currently installed version)
src = zipfile.ZipFile(hap_path, 'r')

# Find module.json and check current state
mod_data = json.loads(src.read('module.json'))
mod = mod_data['module']
print(f'Current hnpPackages: {mod.get("hnpPackages", "NONE")}')

# Add hnpPackages
mod['hnpPackages'] = [{"package": "sct-tools", "type": "private"}]
print(f'Adding hnpPackages: {mod["hnpPackages"]}')

# Write modified module.json to a temp HAP
tmp_hap = hap_path + '.tmp'
dst = zipfile.ZipFile(tmp_hap, 'w', zipfile.ZIP_DEFLATED)

for info in src.infolist():
    if info.filename == 'module.json':
        new_data = json.dumps(mod_data)
        dst.writestr(info, new_data)
    elif not info.is_dir():
        data = src.read(info.filename)
        dst.writestr(info, data)

src.close()
dst.close()

# Replace
shutil.move(tmp_hap, hap_path)
size_mb = os.path.getsize(hap_path) / (1024 * 1024)
print(f'HAP size: {size_mb:.1f} MB')

# Verify no HNP files
with zipfile.ZipFile(hap_path, 'r') as zf:
    hnp_entries = [e for e in zf.namelist() if 'hnp' in e.lower()]
    print(f'HNP entries: {hnp_entries if hnp_entries else "NONE"}')

print('Done - ready to test install')
