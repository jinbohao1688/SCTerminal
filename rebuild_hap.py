import zipfile
import json
import os
import shutil

src_hap = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'
backup = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap.bak'
new_hap = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned-clean.hap'

# Backup original
shutil.copy2(src_hap, backup)
print(f'Backup: {backup}')

# Read original HAP entries
src = zipfile.ZipFile(src_hap, 'r')

# Collect non-HNP entries
non_hnp_entries = []
hnp_names = []
for info in src.infolist():
    if 'hnp' in info.filename.lower():
        hnp_names.append(info.filename)
    else:
        non_hnp_entries.append(info)

print(f'Non-HNP entries: {len(non_hnp_entries)}')
print(f'Old HNP entries: {len(hnp_names)}')
for e in hnp_names:
    print(f'  {e}')

# Create new clean HAP
dst = zipfile.ZipFile(new_hap, 'w', zipfile.ZIP_DEFLATED)

# Add all non-HNP entries
for info in non_hnp_entries:
    if info.is_dir():
        continue
    data = src.read(info.filename)
    dst.writestr(info, data)

# Add fresh HNP files
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

new_size = os.path.getsize(new_hap)
print(f'Clean HAP size: {new_size / 1024 / 1024:.1f} MB')
print(f'Clean HAP: {new_hap}')
print('Done')
