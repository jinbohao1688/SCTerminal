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
        for pkg in data['module'].get('hnpPackages', []):
            if pkg['package'] == 'sct-tools.hnp':
                print('Fixing package: sct-tools.hnp -> sct-tools')
                pkg['package'] = 'sct-tools'
        new_data = json.dumps(data)
        dst.writestr(info, new_data)
    elif not info.is_dir():
        data = src.read(info.filename)
        dst.writestr(info, data)

src.close()
dst.close()

shutil.move(tmp_hap, hap_path)
size = os.path.getsize(hap_path)
print(f'HAP size: {size / 1024 / 1024:.1f} MB')
print('Done')
