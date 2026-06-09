import zipfile
import os
import json

src_dir = 'D:/SCTerminal/tmp_hnp_flat'
output = 'D:/SCTerminal/entry/hnp/arm64-v8a/sct-tools.hnp'

# Create HNP with STORED (no compression)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_STORED) as zf:
    for root, dirs, files in os.walk(src_dir):
        for f in files:
            src_path = os.path.join(root, f)
            rel = os.path.relpath(src_path, src_dir)
            arcname = rel.replace('\\', '/')
            zf.write(src_path, arcname)

size_mb = os.path.getsize(output) / (1024 * 1024)
print(f'Created STORED HNP: {output} ({size_mb:.1f} MB)')

# Verify
with zipfile.ZipFile(output, 'r') as zf:
    e = zf.namelist()[:5]
    print('First entries:')
    for name in e:
        print(f'  {name}')
    print(f'Compression: {zf.infolist()[0].compress_type}')
print('Done')
