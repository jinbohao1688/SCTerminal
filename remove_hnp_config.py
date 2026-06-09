import zipfile
import json
import os
import shutil

hap_path = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'
tmp_hap = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned-tmp.hap'

src = zipfile.ZipFile(hap_path, 'r')
dst = zipfile.ZipFile(tmp_hap, 'w', zipfile.ZIP_DEFLATED)

for info in src.infolist():
    if info.filename == 'module.json':
        data = json.loads(src.read('module.json'))
        module = data['module']
        # Remove hnpPackages completely
        if 'hnpPackages' in module:
            print('Removing hnpPackages from module.json')
            del module['hnpPackages']
        new_data = json.dumps(data)
        dst.writestr(info, new_data)
    elif not info.is_dir() and 'hnp' not in info.filename.lower():
        data = src.read(info.filename)
        dst.writestr(info, data)
    elif 'hnp' not in info.filename.lower():
        data = src.read(info.filename)
        dst.writestr(info, data)

src.close()
dst.close()

shutil.move(tmp_hap, hap_path)
size = os.path.getsize(hap_path)
print(f'HAP size: {size / 1024 / 1024:.1f} MB')

# Verify
with zipfile.ZipFile(hap_path, 'r') as zf:
    mod = json.loads(zf.read('module.json'))
    print(f'hnpPackages in module.json: {mod["module"].get("hnpPackages", "REMOVED")}')
    hnp_entries = [e for e in zf.namelist() if 'hnp' in e.lower()]
    print(f'HNP entries: {hnp_entries}')
print('Done')
