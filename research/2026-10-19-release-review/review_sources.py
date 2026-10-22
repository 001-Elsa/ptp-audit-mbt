#!/usr/bin/env python3
"""Read package ZIP text without executing/extracting third-party source."""
import concurrent.futures,hashlib,io,json,re,subprocess,urllib.parse,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent.relative_to(Path.cwd());OLD=Path('research/2026-10-19-final');DEST=ROOT/'source-review';DEST.mkdir(exist_ok=True)
mods={m['name']:m for m in json.loads((ROOT/'modules.json').read_text())};prior=json.loads((OLD/'source-audit.json').read_text());old={m['name']:m for m in prior}
additional=['golemcloud/golem_sdk_tools','Han-Wentao/mooniso8583','shangwuxi/moonradius','mokomoking2501/concord','btlqql/moon_tracelens','xuting22/rinex','z2823253773-p/moontick','yujieMamba/moonallen','yyyt0807/moonbitemporal','oyjh0381/moonipfix','wcj12314/moon-flow-guard','chen-657/moon-change-window-auditor','Magic486/moonnetlink','LAOBIAO656/moonreplaykit','zhangbowen2006/agentcanary','DDD12345-D/moon-snmp','cstoooo/mooniso_lite','any07557-wq/moonvcs','wiretokenbotca4491/wire_token']
names=list(dict.fromkeys(list(old)+additional));direct=re.compile(r'(?<![a-z])ptp(?![a-z])|1588|bmca|grand.?master|802[._\s]?1[._\s]?as|gptp|precision time protocol|follow.?up|delay.?req|delay.?resp|correction.?field|source.?port.?identity',re.I)
near=re.compile(r'capture.{0,35}(window|epoch)|observation.{0,35}window|request.{0,25}correlat|offline.{0,40}(event|trace|packet)|pending.{0,25}(evict|expire)|timeout.{0,25}(response|request)|independent.{0,25}(evidence|witness)|捕获窗口|观察窗口|报文.{0,12}关联',re.I)
def scan(name):
 m=mods[name];version=m['version'];url='https://download.mooncakes.io/user/'+name+'/'+version+'.zip'
 previous=old.get(name);old_path=OLD/'source-review'/(name.replace('/','__')+'.zip');p=DEST/(name.replace('/','__')+'.zip');mode='fresh_source_zip'
 try:
  if previous and previous.get('version')==version and old_path.exists() and hashlib.sha256(old_path.read_bytes()).hexdigest()==previous['sha256']:
   p=old_path;mode='reused_previous_version_pinned_zip'
  if not p.exists():
   result=subprocess.run(['curl','--compressed','--fail','--location','--max-time','45','--max-filesize','50000000','--silent','--show-error',urllib.parse.quote(url,safe=':/@?=&%')],capture_output=True,timeout=50,check=True)
   p.write_bytes(result.stdout)
  raw=p.read_bytes();z=zipfile.ZipFile(io.BytesIO(raw));hits=[];files=[];skipped=[];total=0
  for f in z.infolist():
   if f.is_dir() or not f.filename.endswith(('.mbt','.mbti','.md','.json','.toml','.txt','.pkg','.mod','.c','.h','.rs','.js','.ts','.py','.yaml','.yml')):continue
   if f.file_size>2_000_000 or total+f.file_size>50_000_000:skipped.append(f.filename);continue
   data=z.read(f);text=data.decode('utf8','replace');total+=len(data);files.append(dict(path=f.filename,bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
   for ln,line in enumerate(text.splitlines(),1):
    labels=[]
    if direct.search(line):labels.append('ptp_specific_token')
    if near.search(line):labels.append('observation_association_neighbor')
    if labels:hits.append(dict(path=f.filename,line=ln,kinds=labels,text=line[:1000]))
  return dict(name=name,version=version,url=url,status='ok',evidence_mode=mode,evidence_file=str(p),sha256=hashlib.sha256(raw).hexdigest(),text_files=len(files),text_bytes=total,skipped=skipped,hits=hits,files=files)
 except Exception as e:return dict(name=name,version=version,url=url,status='failed',evidence_mode=mode,error=str(e))
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:rows=list(pool.map(scan,names))
ROOT.joinpath('source-audit.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print('source',len(rows),'ok',sum(r['status']=='ok' for r in rows),'fresh',sum(r['evidence_mode']=='fresh_source_zip' for r in rows),'files',sum(r.get('text_files',0) for r in rows),'skipped',sum(len(r.get('skipped',[])) for r in rows))
for r in rows:
 if r['status']!='ok':print('FAILED',r)
 elif r['name'] in additional:print(r['name'],'files',r['text_files'],'hits',len(r['hits']))
