"""Read selected published ZIPs without executing or extracting third-party code."""
import json,re,hashlib,subprocess,concurrent.futures,zipfile,io,urllib.parse,argparse
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--root',default='research/2026-10-19-redesign');parser.add_argument('--extra',action='append',default=[]);args=parser.parse_args()
root=Path(args.root);dest=root/'source-review';dest.mkdir(parents=True,exist_ok=True)
mods={m['name']:m for m in json.load(open(root/'modules.json'))}
names=['mokomoking2501/fieldbus_core','mokomoking2501/lockwire','mokomoking2501/profinet_master','mokomoking2501/MoonECAT','CJR-ai-nb/evowitness','HhWw96/moontxnwitness','length-super/moonctl','cghyyrrt/moonbit-pcap','vicTop-cw/mcpconftest','xuting22/ntp','Ljh684/moonnet-lab','lxyhgvb/moonbit-radioframe','sbqrre/moonbit-mcu-hal','oyjh0381/moonlab','cauchyQ/moonbit-causalkit','SCL-NN/moontracekit','zlhahaha/moonsim','wcx789ll/moonsim','usagi-star/mooncap']
names += ['bzy-debug/hello','moonbitlang/core','BigOrangeQWQ/wit-wasi-clocks','BigOrangeQWQ/wit-wasi-io','CAIMEOX/原来可以发中文包','illusory0x0/🐫','moonbit-community/moongrep-skill','tonyfettes/ssl']
names=list(dict.fromkeys(names+args.extra))
pat=re.compile(r'(?<![a-z])ptp(?![a-z])|1588|bmca|grand.?master|802[._\s]?1[._\s]?as|gptp|precision time protocol|follow.?up|correction.?field',re.I)
def scan(n):
 m=mods[n];url='https://download.mooncakes.io/user/'+n+'/'+m['version']+'.zip';p=dest/(n.replace('/','__')+'.zip')
 try:
  if not p.exists():p.write_bytes(subprocess.run(['curl','--compressed','--fail','--location','--max-time','45','--max-filesize','50000000','--silent','--show-error',urllib.parse.quote(url,safe=':/@?=&%')],capture_output=True,check=True,timeout=50).stdout)
  b=p.read_bytes();z=zipfile.ZipFile(io.BytesIO(b));hits=[];count=0;total=0;skipped=[]
  for f in z.infolist():
   if f.is_dir() or not f.filename.endswith(('.mbt','.mbti','.md','.json','.toml','.txt','.pkg','.mod','.c','.h','.rs','.js','.ts','.py')):continue
   if f.file_size>2_000_000 or total+f.file_size>50_000_000:skipped.append(f.filename);continue
   s=z.read(f).decode('utf8','replace');total+=f.file_size;count+=1
   for ln,line in enumerate(s.splitlines(),1):
    if pat.search(line):hits.append({'path':f.filename,'line':ln,'text':line[:600]})
  return dict(name=n,version=m['version'],url=url,status='ok',sha256=hashlib.sha256(b).hexdigest(),text_files=count,text_bytes=total,skipped=skipped,hits=hits)
 except Exception as e:return dict(name=n,url=url,status='failed',error=str(e))
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:results=list(pool.map(scan,names))
json.dump(results,open(root/'source-audit.json','w'),ensure_ascii=False,indent=2)
for r in results:
 print(r['name'],r['status'],'files',r.get('text_files'),'hits',len(r.get('hits',[])))
 for h in r.get('hits',[])[:8]:print(h)
