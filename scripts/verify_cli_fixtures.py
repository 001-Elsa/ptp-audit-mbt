#!/usr/bin/env python3
"""Execute every on-disk fixture through the shipping CLI and check reports/exit codes."""
import hashlib,json,subprocess,sys,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1];manifest=json.loads((root/'fixtures/manifest.json').read_text())
code={'Pass':0,'Violation':1,'InsufficientEvidence':3,'Unsupported':4};fail=[]
for i,row in enumerate(manifest['cases'],1):
 p=root/row['path']
 if hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:fail.append((row['name'],'fixture SHA-256 differs from independent manifest'))
 r=subprocess.run([str(root/'bin/ptp-audit.mjs'),'check',str(p),'--json'],cwd=root,text=True,capture_output=True)
 try:data=json.loads(r.stdout)
 except Exception:fail.append((row['name'],'non-json',r.returncode,r.stdout[-200:],r.stderr[-200:]));continue
 actual=data.get('status');ec=data.get('exit_code')
 if actual!=row['status'] or r.returncode!=code[row['status']] or ec!=code[row['status']]:fail.append((row['name'],row['status'],actual,code[row['status']],r.returncode,ec))
 if row['rule'] not in [f['rule'] for f in data['findings']]:fail.append((row['name'],'missing expected rule',row['rule']))
 ms=data.get('measurements',[])
 if row['measurement']:
  if len(ms)!=1 or any(ms[0].get(k)!=v for k,v in row['measurement'].items()):fail.append((row['name'],'measurement mismatch',ms,row['measurement']))
 elif ms:fail.append((row['name'],'unexpected measurement',ms))
 print(f'{i:02d} {row["name"]}: expected={row["status"]} actual={actual} exit={r.returncode}')
# Exercise CLI-only I/O/UTF-8/usage paths without needing a network or compiler mutation.
with tempfile.TemporaryDirectory(prefix='ptp-cli-boundaries-') as tmp:
 tmp=Path(tmp);(tmp/'bad-utf8.json').write_bytes(b'\xff\xfe');(tmp/'too-large.json').write_bytes(b' '*1048577)
 boundaries=[([],2),(['--help'],0),(['--version'],0),(['check',str(tmp/'missing.json')],2),(['check',str(tmp)],2),(['check',str(tmp/'bad-utf8.json')],2),(['check',str(tmp/'too-large.json')],2)]
 for args,expected in boundaries:
  r=subprocess.run([str(root/'bin/ptp-audit.mjs'),*args],cwd=root,text=True,capture_output=True)
  if r.returncode!=expected:fail.append(('CLI boundary',args,expected,r.returncode,r.stderr[-200:]))
print('CLI boundary checks: 7')
if fail:print('FAILURES',json.dumps(fail,ensure_ascii=False,indent=2));sys.exit(1)
print(f'CLI fixture regression passed: {len(manifest["cases"])} cases plus 7 boundaries')
