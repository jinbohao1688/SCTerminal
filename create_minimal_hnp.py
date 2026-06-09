import zipfile
import os
import json

# Create a minimal HNP with just one tiny binary
minimal_dir = 'D:/SCTerminal/tmp_minimal_hnp'
os.makedirs(minimal_dir, exist_ok=True)

# hnp.json
config = {
    "type": "hnp-config",
    "name": "sct-tools",
    "version": "1.0.0",
    "install": {}
}
with open(os.path.join(minimal_dir, 'hnp.json'), 'w') as f:
    json.dump(config, f, indent=2)

# bin dir with a minimal "hello" script
os.makedirs(os.path.join(minimal_dir, 'bin'), exist_ok=True)
with open(os.path.join(minimal_dir, 'bin', 'hello'), 'w') as f:
    f.write('#!/bin/sh\necho hello\n')

# Create minimal HNP
output = 'D:/SCTerminal/entry/hnp/arm64-v8a/sct-tools.hnp'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_STORED) as zf:
    for root, dirs, files in os.walk(minimal_dir):
        for fname in files:
            src = os.path.join(root, fname)
            rel = os.path.relpath(src, minimal_dir)
            zf.write(src, rel.replace('\\', '/'))

size = os.path.getsize(output)
print(f'Minimal HNP: {output} ({size} bytes)')

# List contents
with zipfile.ZipFile(output, 'r') as zf:
    for info in zf.infolist():
        print(f'  {info.filename} ({info.file_size} bytes)')
print('Done')
