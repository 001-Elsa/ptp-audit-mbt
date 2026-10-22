"""Read-only scan of every module's public root documentation; no package execution."""
import argparse
import subprocess
import json, re, time, hashlib, urllib.request, urllib.parse, concurrent.futures
from pathlib import Path
from html.parser import HTMLParser
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--root',default='research/2026-10-19')
parser.add_argument('--workers',type=int,default=16)
args=parser.parse_args()
ROOT=Path(args.root); (ROOT/'pages').mkdir(parents=True,exist_ok=True)
class Text(HTMLParser):
 def __init__(self):super().__init__();self.skip=0;self.out=[]
 def handle_starttag(self,t,a):
  if t in ('script','style'):self.skip+=1
 def handle_endtag(self,t):
  if t in ('script','style'):self.skip=max(0,self.skip-1)
 def handle_data(self,d):
  if not self.skip and d.strip():self.out.append(d.strip())
strong=re.compile(r'(?<![a-z])ptp(?![a-z])|1588|bmca|grand.?master|802[._\s]?1[._\s]?as|gptp|precision time protocol|精密时间|精确时间协议',re.I)
near=re.compile(r'clock.{0,35}sync|time.{0,25}synchroniz|\bservo\b|时钟同步|时间同步|\bNTP\b|\bSNTP\b|network simulator|distributed.system.{0,25}simulat|causal.clock|logical.clock|discrete.event',re.I)
def scan(m):
 name=m['name'];url='https://mooncakes.io/docs/'+name+'@'+m['version'];key=name.replace('/','__')+'--'+hashlib.sha256((name+'@'+m['version']).encode()).hexdigest()[:12];p=ROOT/'pages'/(key+'.txt')
 try:
  if p.exists():s=p.read_text()
  else:
   raw=subprocess.run(['curl','--compressed','--fail','--location','--max-time','45','--silent','--show-error',urllib.parse.quote(url,safe=':/@?=&%')],capture_output=True,timeout=50,check=True).stdout.decode('utf8','replace');t=Text();t.feed(raw);s=' '.join(t.out);p.write_text(s)
  hits=[]
  for label,pat in [('direct',strong),('neighbor',near)]:
   matches=list(pat.finditer(s));
   if matches:hits.append({'kind':label,'count':len(matches),'excerpts':[s[max(0,x.start()-140):x.end()+200] for x in matches[:20]]})
  return {'name':name,'version':m['version'],'url':url,'evidence_file':str(p),'status':('unavailable' if 'Docs unavailable' in s and 'Documentation assets could not be loaded' in s else 'ok'),'chars':len(s),'sha256':hashlib.sha256(s.encode()).hexdigest(),'hits':hits}
 except Exception as e:return {'name':name,'url':url,'evidence_file':str(p),'status':'failed','error':str(e)}
mods=json.load(open(ROOT/'modules.json'));results=[];started=time.time()
with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
 for r in pool.map(scan,mods):
  results.append(r)
  if len(results)%200==0:print('processed',len(results),'of',len(mods),flush=True)
json.dump(results,open(ROOT/'page-audit.json','w'),ensure_ascii=False,indent=2)
summary={'total':len(mods),'ok':sum(r['status']=='ok' for r in results),'failed':sum(r['status']=='failed' for r in results),'unavailable':sum(r['status']=='unavailable' for r in results),'direct':[r['name'] for r in results if any(h['kind']=='direct' for h in r.get('hits',[]))],'neighbors':[r['name'] for r in results if any(h['kind']=='neighbor' for h in r.get('hits',[]))],'seconds':round(time.time()-started)}
json.dump(summary,open(ROOT/'summary.json','w'),ensure_ascii=False,indent=2);print(json.dumps(summary,ensure_ascii=False),flush=True)
