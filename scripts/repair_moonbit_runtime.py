#!/usr/bin/env python3
"""Download the exact MoonBit Apple Silicon bundle used by this project and restore missing runtime files."""
from pathlib import Path
import hashlib, json, os, shutil, sys, tarfile, tempfile, urllib.request
URL='https://cli.moonbitlang.com/binaries/0.10.15%2B943464bfa/moonbit-darwin-aarch64.tar.gz'
SHA256='563109ff02c6dc77fdc74acd0be423964ef678dfea4d9b948c19d245dc8b0e83'
MOON_ROOT=Path(os.environ.get('MOON_HOME',Path.home()/'.moon')).expanduser()
if sys.platform!='darwin' or os.uname().machine not in ('arm64','aarch64'):
    raise SystemExit('This repair recipe is for the tested Apple Silicon macOS toolchain; use the official installer on other platforms.')
archive_fd,archive_name=tempfile.mkstemp(prefix='moonbit-runtime-',suffix='.tar.gz')
os.close(archive_fd)
archive=Path(archive_name)
try:
    print('Downloading',URL)
    with urllib.request.urlopen(URL,timeout=180) as src, archive.open('wb') as dst:
        shutil.copyfileobj(src,dst)
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest!=SHA256:raise SystemExit(f'archive SHA-256 mismatch: {digest}')
    changed=[]
    with tarfile.open(archive) as tar:
        for member in tar.getmembers():
            name=member.name.removeprefix('./')
            if not name.startswith(('lib/','include/','bin/internal/')):continue
            dest=MOON_ROOT/name
            if member.isdir():dest.mkdir(parents=True,exist_ok=True);continue
            if not member.isfile():continue
            dest.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists():continue
            data=tar.extractfile(member).read();dest.write_bytes(data);dest.chmod(member.mode);changed.append(str(dest))
    manifest=Path(__file__).resolve().parents[1]/'research/toolchain-repair/manifest.json'
    manifest.parent.mkdir(parents=True,exist_ok=True)
    if manifest.exists():
        manifest=manifest.with_name('rerun-'+str(os.getpid())+'.json')
    manifest.write_text(json.dumps({'download_url':URL,'archive_sha256':SHA256,'moon_home':str(MOON_ROOT),'changed_files':changed,'policy':'restore missing runtime/include files only; preserve compiler and existing files'},indent=2)+'\n')
    print(f'Restored {len(changed)} missing files under {MOON_ROOT}')
finally:
    archive.unlink(missing_ok=True)
