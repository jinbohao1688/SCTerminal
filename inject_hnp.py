import zipfile
import os

hap_path = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'
hnp_dir = 'D:/SCTerminal/entry/hnp'

old_size = os.path.getsize(hap_path)
print(f'HAP before: {old_size / 1024 / 1024:.1f} MB')

hap = zipfile.ZipFile(hap_path, 'a')
count = 0
for root, dirs, files in os.walk(hnp_dir):
    for f in files:
        src = os.path.join(root, f)
        rel = os.path.relpath(src, 'D:/SCTerminal')
        arcname = rel.replace('\\', '/')
        print(f'Adding: {arcname}')
        hap.write(src, arcname)
        count += 1
hap.close()

new_size = os.path.getsize(hap_path)
print(f'Added {count} files')
print(f'HAP after: {new_size / 1024 / 1024:.1f} MB')
print('Done')
