#!/usr/bin/env python3
"""Fresh complete index, bounded fresh document delta, and explicit reused evidence."""
import concurrent.futures,hashlib,json,re,subprocess,time,urllib.parse
from pathlib import Path
from datetime import datetime,timezone
from html.parser import HTMLParser
ROOT=Path(__file__).resolve().parent.relative_to(Path.cwd());OLD=Path('research/2026-10-19-final')
ROOT.joinpath('pages').mkdir(exist_ok=True)
mods=json.loads((ROOT/'modules.json').read_text());prior=json.loads((OLD/'modules.json').read_text());old={m['name']:m for m in prior};pages={r['name']:r for r in json.loads((OLD/'page-audit.json').read_text())}
changes=[dict(name=m['name'],old_version=old.get(m['name'],{}).get('version'),new_version=m['version'],kind='new_name' if m['name'] not in old else 'new_version',description=m.get('description'),keywords=m.get('keywords')) for m in mods if m['name'] not in old or m['version']!=old[m['name']]['version']]
metadata=[dict(name=m['name'],version=m['version'],changed_fields=[k for k in set(m)|set(old[m['name']]) if m.get(k)!=old[m['name']].get(k)]) for m in mods if m['name'] in old and m['version']==old[m['name']]['version'] and m!=old[m['name']]]
additional=['Han-Wentao/mooniso8583','shangwuxi/moonradius','mokomoking2501/concord','btlqql/moon_tracelens','xuting22/rinex','z2823253773-p/moontick','yujieMamba/moonallen','yyyt0807/moonbitemporal','oyjh0381/moonipfix','wcj12314/moon-flow-guard','chen-657/moon-change-window-auditor','Magic486/moonnetlink','LAOBIAO656/moonreplaykit','zhangbowen2006/agentcanary','usagi-star/mooncap','cghyyrrt/moonbit-pcap','xuting22/ntp','mokomoking2501/profinet_master','mokomoking2501/fieldbus_core','mokomoking2501/lockwire','vicTop-cw/mcpconftest']
fresh_names={r['name'] for r in changes}|{r['name'] for r in pages.values() if r['status']!='ok'}|set(additional)|{r['name'] for r in json.loads((OLD/'screening-review.json').read_text())}
strong=re.compile(r'(?<![a-z])ptp(?![a-z])|1588|bmca|grand.?master|802[._\s]?1[._\s]?as|gptp|precision time protocol|精密时间|精确时间协议',re.I)
near=re.compile(r'clock.{0,35}sync|time.{0,25}synchroniz|\bservo\b|时钟同步|时间同步|\bNTP\b|\bSNTP\b|network simulator|distributed.system.{0,25}simulat|causal.clock|logical.clock|discrete.event',re.I)
newcore=re.compile(r'follow.?up|delay.?req|delay.?resp|source.?port.?identity|correction.?field|best.?master.?clock|capture.{0,25}(window|epoch)|observation.{0,25}window|request.{0,20}correlat|offline.{0,35}(packet|trace|event)|报文.{0,15}(关联|审计)|捕获窗口|观察窗口',re.I)
class Text(HTMLParser):
 def __init__(self):super().__init__();self.skip=0;self.out=[]
 def handle_starttag(self,t,a):
  if t in ('script','style'):self.skip+=1
 def handle_endtag(self,t):
  if t in ('script','style'):self.skip=max(0,self.skip-1)
 def handle_data(self,d):
  if not self.skip and d.strip():self.out.append(d.strip())
def hits(text):
 out=[]
 for name,pat in [('direct',strong),('neighbor',near),('association_observation',newcore)]:
  ms=list(pat.finditer(text))
  if ms:out.append(dict(kind=name,count=len(ms),excerpts=[text[max(0,x.start()-120):x.end()+180] for x in ms[:20]]))
 return out
def scan(m):
 name=m['name'];version=m['version'];url='https://mooncakes.io/docs/'+name+'@'+version
 if name not in fresh_names and name in pages and pages[name].get('version')==version:
  r=dict(pages[name]);s=Path(r['evidence_file']).read_text();r.update(evidence_mode='reused_previous_version_pinned_snapshot',hits=hits(s));return r
 key=name.replace('/','__')+'--'+hashlib.sha256((name+'@'+version).encode()).hexdigest()[:12];p=ROOT/'pages'/(key+'.txt')
 try:
  if not p.exists():
   error=None
   for attempt in range(3):
    result=subprocess.run(['curl','--compressed','--fail','--location','--max-time','35','--silent','--show-error',urllib.parse.quote(url,safe=':/@?=&%')],capture_output=True,timeout=40)
    if result.returncode==0:
     t=Text();t.feed(result.stdout.decode('utf8','replace'));p.write_text(' '.join(t.out));break
    error=result.stderr.decode('utf8','replace')[-600:]
   if not p.exists():raise RuntimeError(error)
  s=p.read_text();status='unavailable' if 'Docs unavailable' in s and 'Documentation assets could not be loaded' in s else 'limited' if 'Build failed' in s or 'does not have a README file' in s else 'ok'
  return dict(name=name,version=version,url=url,evidence_file=str(p),evidence_mode='fresh_network_document',status=status,chars=len(s),sha256=hashlib.sha256(s.encode()).hexdigest(),hits=hits(s))
 except Exception as e:return dict(name=name,version=version,url=url,evidence_mode='fresh_network_document',status='failed',error=str(e))
start=datetime.now(timezone.utc).isoformat()
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:rows=list(pool.map(scan,mods))
metadata_hits=[]
for m in mods:
 text=json.dumps({k:m.get(k) for k in ['name','description','keywords']},ensure_ascii=False);h=hits(text)
 if h:metadata_hits.append(dict(name=m['name'],version=m['version'],description=m.get('description'),hits=h))
summary=dict(generated_at=datetime.now(timezone.utc).isoformat(),started_at=start,index_total=len(mods),index_yanked=sum(bool(m.get('yanked')) for m in mods),new_names=sum(r['kind']=='new_name' for r in changes),updated_versions=sum(r['kind']=='new_version' for r in changes),same_version_metadata_changes=len(metadata),removed_names=sorted(set(old)-{m['name'] for m in mods}),fresh_documents=sum(r['evidence_mode']=='fresh_network_document' for r in rows),reused_documents=sum(r['evidence_mode']!='fresh_network_document' for r in rows),ok=sum(r['status']=='ok' for r in rows),unavailable=sum(r['status']=='unavailable' for r in rows),failed=sum(r['status']=='failed' for r in rows),limited=sum(r['status']=='limited' for r in rows),root_hit_modules=sum(bool(r.get('hits')) for r in rows),metadata_hit_modules=len(metadata_hits),index_sha256=hashlib.sha256((ROOT/'modules.json').read_bytes()).hexdigest())
for name,data in [('index-delta.json',dict(changes=changes,metadata_changes=metadata)),('page-audit.json',rows),('metadata-hits.json',metadata_hits),('summary.json',summary)]:ROOT.joinpath(name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(summary,ensure_ascii=False));print('fresh failures',[(r['name'],r.get('error')) for r in rows if r['status']=='failed'])
