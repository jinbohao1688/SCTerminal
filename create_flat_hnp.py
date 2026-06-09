import zipfile
import os
import json

src_dir = 'D:/SCTerminal/tmp_hnp_flat'
output_arm64 = 'D:/SCTerminal/entry/hnp/arm64-v8a/sct-tools.hnp'
output_x86_64 = 'D:/SCTerminal/entry/hnp/x86_64/sct-tools.hnp'

# Create HNP with FLAT structure (no top-level directory)
# Files are at root level: bin/busybox, lib/..., hnp.json

def create_hnp(src, output):
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(src):
            for f in files:
                src_path = os.path.join(root, f)
                rel = os.path.relpath(src_path, src)
                arcname = rel.replace('\\', '/')
                print(f'  Adding: {arcname}')
                zf.write(src_path, arcname)
    size_mb = os.path.getsize(output) / (1024 * 1024)
    print(f'  Created: {output} ({size_mb:.1f} MB)')

print('Creating flat ARM64 HNP...')
create_hnp(src_dir, output_arm64)

# Also create x86_64 HNP with same flat structure
src_x86 = 'D:/SCTerminal/tmp_hnp_x86_flat'
if os.path.exists(src_x86):
    print('Creating flat x86_64 HNP...')
    create_hnp(src_x86, output_x86_64)
else:
    print('x86_64 src not found, creating from x86_64 HNP...')
    # Extract x86_64 HNP
    x86_hnp = 'D:/SCTerminal/entry/hnp/x86_64/sct-tools.hnp'
    if os.path.exists(x86_hnp):
        src_out = 'D:/SCTerminal/tmp_hnp_x86_flat'
        os.makedirs(src_out, exist_ok=True)
        with zipfile.ZipFile(x86_hnp, 'r') as zf:
            for info in zf.infolist():
                name = info.filename
                # Remove top-level directory prefix (sysroot/ or sct-tools/ etc)
                parts = name.split('/', 1)
                if len(parts) > 1:
                    name = parts[1]
                if not name:
                    continue
                target = os.path.join(src_out, name)
                if info.is_dir():
                    os.makedirs(target, exist_ok=True)
                else:
                    os.makedirs(os.path.dirname(target), exist_ok=True)
                    with open(target, 'wb') as f:
                        f.write(zf.read(info))
        # Also ensure hnp.json has correct version
        hnp_json = os.path.join(src_out, 'hnp.json')
        if os.path.exists(hnp_json):
            with open(hnp_json, 'r') as f:
                cfg = json.load(f)
            cfg['version'] = '1.0.0'
            with open(hnp_json, 'w') as f:
                json.dump(cfg, f, indent=2)
        create_hnp(src_out, output_x86_64)

print('Done')
