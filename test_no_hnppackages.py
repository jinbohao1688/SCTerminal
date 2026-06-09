import zipfile
import json
import os
import shutil

hap_path = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'

# Start from base HAP that installed successfully (3MB)
src = zipfile.ZipFile(hap_path, 'r')

# Check current state
mod = json.loads(src.read('module.json'))
print(f'Current hnpPackages: {mod["module"].get("hnpPackages", "NONE")}')

# Remove hnpPackages if present
if 'hnpPackages' in mod['module']:
    del mod['module']['hnpPackages']
    print('Removed hnpPackages')

# Create new HAP with HNP files but WITHOUT hnpPackages
tmp_hap = hap_path + '.tmp'
dst = zipfile.ZipFile(tmp_hap, 'w', zipfile.ZIP_DEFLATED)

for info in src.infolist():
    if info.filename == 'module.json':
        new_data = json.dumps(mod)
        dst.writestr(info, new_data)
    elif not info.is_dir() and 'hnp' not in info.filename.lower():
        data = src.read(info.filename)
        dst.writestr(info, data)

# Add HNP files
hnp_dir = 'D:/SCTerminal/entry/hnp'
for root, dirs, files in os.walk(hnp_dir):
    for f in files:
        src_path = os.path.join(root, f)
        rel = os.path.relpath(src_path, 'D:/SCTerminal')
        arcname = rel.replace('\\', '/')
        print(f'Adding: {arcname}')
        dst.write(src_path, arcname)

src.close()
dst.close()

shutil.move(tmp_hap, hap_path)
size_mb = os.path.getsize(hap_path) / (1024 * 1024)
print(f'HAP size: {size_mb:.1f} MB')

# Verify
with zipfile.ZipFile(hap_path, 'r') as zf:
    mod = json.loads(zf.read('module.json'))
    print(f'hnpPackages in module.json: {mod["module"].get("hnpPackages", "REMOVED")}')
    hnp_entries = [e for e in zf.namelist() if 'hnp' in e.lower()]
    print(f'HNP entries: {len(hnp_entries)}')
    for e in hnp_entries:
        print(f'  {e}')
print('Done')
