import zipfile

files = [
    ('hnpcli tmp_hnp_final', 'D:/SCTerminal/tmp_hnp_final/sct-tools.hnp'),
    ('Python flat ARM64', 'D:/SCTerminal/entry/hnp/arm64-v8a/sct-tools.hnp'),
    ('x86_64 HNP', 'D:/SCTerminal/entry/hnp/x86_64/sct-tools.hnp'),
]

for label, path in files:
    try:
        zf = zipfile.ZipFile(path, 'r')
        info = zf.infolist()[2]  # First real file
        print(f'{label}:')
        print(f'  compress_type: {info.compress_type} (0=STORED, 8=DEFLATED)')
        print(f'  create_system: {info.create_system}')
        print(f'  create_version: {info.create_version}')
        print(f'  extract_version: {info.extract_version}')
        print(f'  flag_bits: {info.flag_bits}')
        names = zf.namelist()[:5]
        print(f'  First entries: {names}')
        zf.close()
        print()
    except Exception as e:
        print(f'{label}: ERROR {e}')
        print()
