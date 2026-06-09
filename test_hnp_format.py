import zipfile
import json
import os
import shutil

hap_path = 'D:/SCTerminal/entry/build/default/outputs/default/entry-default-unsigned.hap'

# Create test with hnpPackages as object instead of array
src = zipfile.ZipFile(hap_path, 'r')
tmp_hap = hap_path + '.test'

# Read module.json
mod_data = json.loads(src.read('module.json'))

# Try different hnpPackages format
# Format 1: Object with package name as key
mod_data['module']['hnpPackages'] = {
    "sct-tools": {
        "package": "sct-tools",
        "type": "private"
    }
}
print(f'hnpPackages (object format): {json.dumps(mod_data["module"]["hnpPackages"])}')

# Also ensure pkgContextInfo has sct-tools entry
try:
    pkg_data = json.loads(src.read('pkgContextInfo.json'))
except:
    pkg_data = {}

pkg_data['sct-tools'] = {
    "isSO": False,
    "moduleName": "",
    "bundleName": "",
    "dependencyAlias": "",
    "packageName": "sct-tools",
    "entryPath": "",
    "version": "1.0.0"
}
print(f'Added sct-tools to pkgContextInfo')

# Write new HAP
dst = zipfile.ZipFile(tmp_hap, 'w', zipfile.ZIP_DEFLATED)
for info in src.infolist():
    if info.filename == 'module.json':
        dst.writestr(info, json.dumps(mod_data))
    elif info.filename == 'pkgContextInfo.json':
        dst.writestr(info, json.dumps(pkg_data))
    elif not info.is_dir():
        data = src.read(info.filename)
        dst.writestr(info, data)

# Verify HNP files are present
hnp_count = 0
for info in src.infolist():
    if 'hnp' in info.filename.lower() and not info.is_dir():
        hnp_count += 1
        # Need to re-add these since we're filtering
        data = src.read(info.filename)
        if info not in [e for e in dst.infolist() if not e.is_dir()]:
            dst.writestr(info, data)
            hnp_count += 1

src.close()
dst.close()

# Actually, let me rewrite this more carefully
# The issue is we might double-add files. Let me just modify module.json and pkgContextInfo.json

# Simpler approach: modify in-place
print(f'HNP count in source: {hnp_count}')

shutil.move(tmp_hap, hap_path)
size_mb = os.path.getsize(hap_path) / (1024 * 1024)
print(f'HAP size: {size_mb:.1f} MB')

# Verify
with zipfile.ZipFile(hap_path, 'r') as zf:
    mod = json.loads(zf.read('module.json'))
    print(f'hnpPackages: {json.dumps(mod["module"].get("hnpPackages","NONE"))}')
    hnp_entries = [e for e in zf.namelist() if 'hnp' in e.lower()]
    print(f'HNP entries: {len(hnp_entries)}')
print('Done')
