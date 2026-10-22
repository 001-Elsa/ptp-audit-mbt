#!/usr/bin/env python3
"""Resume a version-pinned, read-only scan of every official Mooncakes module.

Downloaded archives remain outside the project; no package code is executed or
extracted. Results distinguish complete scans from unavailable or limited scans.
This is a reproducible keyword/source inventory, not an absolute originality proof.
"""
from __future__ import annotations
import argparse, concurrent.futures, datetime, email.utils, hashlib, json, os, pathlib, re
import codecs, gzip, http.client, ssl, shutil, socket, subprocess, sys, threading, time, urllib.error, urllib.parse, urllib.request, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'research/full-source-audit'
CACHE = pathlib.Path.home() / '.local/share/ptp-audit-tools/mooncakes-source-cache'
INDEX_URL = 'https://mooncakes.io/api-new/v0/modules'
SCANNER_VERSION = 4
SCANNER_SHA256 = hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()
OFFICIAL_CDN = 'https://d15l9c1mnzh3r.cloudfront.net'
# These finite safety bounds are part of the evidence, never silently passed.
MAX_DOWNLOAD = 512 * 1024 * 1024
MAX_MEMBER = 512 * 1024 * 1024
MAX_EXPANDED = 2 * 1024 * 1024 * 1024
MAX_MEMBERS = 100_000
TEXT_EXT = {'.mbt','.mbti','.md','.markdown','.txt','.rst','.json','.jsonl','.toml','.yaml','.yml','.c','.h','.cc','.cpp','.hpp','.rs','.py','.js','.mjs','.cjs','.ts','.tsx','.jsx','.sh','.bash','.zsh','.html','.htm','.css','.xml','.svg','.ini','.cfg','.conf','.csv','.tsv','.sql','.proto','.go','.java','.kt','.kts','.swift','.scala','.rb','.ex','.exs','.erl','.hrl','.hs','.ml','.mli','.lua','.pl','.pm','.r','.jl','.vue','.svelte','.typ','.tex','.bib','.ipynb','.wat','.wasmtext','.mod','.pkg','.lock','.gitignore'}
BINARY_EXT = {'.png','.jpg','.jpeg','.gif','.webp','.ico','.pdf','.woff','.woff2','.ttf','.otf','.mp4','.mov','.wav','.mp3','.zip','.gz','.tar','.bz2','.xz','.7z','.exe','.dll','.dylib','.so','.a','.o','.wasm','.core','.mi','.mio','.pyc','.bin','.dat','.pcap','.pcapng'}
EXACT = {
 'ptp_protocol': re.compile(r'(?i)(?<![a-z0-9])g?ptp(?![a-z0-9])|\bg?ptp(?:[_-][a-z0-9_]+|(?:timestamp|time|message|header|packet|port|clock|delay|sync|announce|audit|parser|decoder)[a-z0-9_]*)\b|\b(?:linuxptp|ptpd|ptp4l|phc2sys|ts2phc)\b|802[._ -]?1[._ -]?AS|\bprecision[ _-]*time[ _-]*protocol\b|精确时间协议|精密时间协议'),
 'ieee1588_context': re.compile(r'(?i)\b(?:IEEE[ _:-]*)?1588(?:[-:]20(?:02|08|19))?\b'),
 'bmca': re.compile(r'(?i)(?<![a-z0-9])bmca(?![a-z0-9])|\bbmca(?:dataset|candidate|clock|audit|compar)[a-z0-9_]*\b|best[ _-]*master[ _-]*clock|grand[ _-]*master|offset[ _-]*scaled[ _-]*log[ _-]*variance'),
 'correction_field': re.compile(r'(?i)correction[ _-]*field'),
 'port_identity': re.compile(r'(?i)(?:source|requesting)[ _-]*port[ _-]*identity'),
 'ptp_messages': re.compile(r'(?i)\bfollow[ _-]*up\b|\bdelay[ _-]*(?:req|resp)\b|\bpdelay[ _-]*(?:req|resp)\b|\b(?:two[ _-]*step[ _-]*flag|grandmasteridentity|logmessageinterval|stepsremoved)\b'),
}
NEAR = {
 'clock_sync': re.compile(r'(?i)(?:clock.{0,35}(?:synchro|offset|drift|master)|(?:synchro|offset|drift|master).{0,35}clock)'),
 'protocol_capture_audit': re.compile(r'(?i)(?:offline.{0,35}(?:trace|packet|protocol|capture)|(?:protocol|packet|capture|trace).{0,35}(?:audit|validat|verif|monitor))'),
 'request_response_deadline': re.compile(r'(?i)(?:request.{0,50}response.{0,50}(?:timeout|deadline|correlat)|(?:timeout|deadline|correlat).{0,50}request.{0,50}response)'),
}
CONNECTIONS = threading.local()

def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha_file(p):
 h=hashlib.sha256()
 with open(p,'rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def key(name,version): return hashlib.sha256((name+'\0'+version).encode()).hexdigest()
def atomic(path,value):
 path.parent.mkdir(parents=True,exist_ok=True)
 tmp=path.with_suffix(path.suffix+'.tmp')
 tmp.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
 tmp.replace(path)
def open_response(url):
 # Preserve ordinary TLS verification and reuse connections per worker. The
 # official download endpoint redirects to storage; opening a new TLS session
 # for both hosts on every archive needlessly doubles network latency.
 current=url
 pool=getattr(CONNECTIONS,'pool',None)
 if pool is None:pool={};CONNECTIONS.pool=pool
 for _ in range(8):
  parsed=urllib.parse.urlsplit(current)
  if parsed.scheme!='https':raise ValueError('non-HTTPS redirect refused: '+current)
  host=parsed.netloc
  conn=pool.get(host)
  if conn is None:
   conn=http.client.HTTPSConnection(host,timeout=45,context=ssl.create_default_context());pool[host]=conn
  path=urllib.parse.urlunsplit(('', '', parsed.path or '/', parsed.query, ''))
  try:
   conn.request('GET',path,headers={'User-Agent':'PTP-Audit-source-inventory/0.3 (read-only; MoonBit contest review)','Accept-Encoding':'gzip'})
   r=conn.getresponse()
  except Exception:
   conn.close();pool.pop(host,None);raise
  if r.status in (301,302,303,307,308):
   location=r.getheader('Location');r.read()
   if not location:raise ValueError('redirect missing Location')
   current=urllib.parse.urljoin(current,location);continue
  if r.status>=400:
   code=r.status;headers=r.headers;r.read()
   raise urllib.error.HTTPError(current,code,r.reason,headers,None)
  return r
 raise ValueError('redirect limit exceeded')

def fetch(url,dest=None,retries=5):
 for attempt in range(retries):
  try:
   with open_response(url) as r:
    size=int(r.headers.get('Content-Length') or 0)
    if size>MAX_DOWNLOAD:raise ValueError(f'archive_download_limit: advertised {size} > {MAX_DOWNLOAD}')
    total=0;chunks=[]
    stream=gzip.GzipFile(fileobj=r) if r.headers.get('Content-Encoding')=='gzip' else r
    f=open(dest,'wb') if dest else None
    try:
     while True:
      b=stream.read(1024*1024)
      if not b:break
      total+=len(b)
      if total>MAX_DOWNLOAD:raise ValueError(f'archive_download_limit: received > {MAX_DOWNLOAD}')
      if f:f.write(b)
      else:chunks.append(b)
    finally:
     if f:f.close()
    return b''.join(chunks) if not dest else total
  except urllib.error.HTTPError as e:
   if e.code not in (408,425,429,500,502,503,504) or attempt==retries-1:raise
   retry=e.headers.get('Retry-After','')
   try:delay=max(float(retry),2**attempt)
   except ValueError:
    try:delay=max((email.utils.parsedate_to_datetime(retry)-datetime.datetime.now(datetime.timezone.utc)).total_seconds(),2**attempt)
    except (ValueError,TypeError):delay=2**attempt
   # Do not cap a server-requested Retry-After into a shorter wait.
   while delay>0:
    step=min(delay,60);time.sleep(step);delay-=step
  except (TimeoutError,ConnectionError,OSError,urllib.error.URLError,http.client.HTTPException):
   # A timed-out partial HTTP body must never be reused as the next response.
   for connection in getattr(CONNECTIONS,'pool',{}).values():connection.close()
   CONNECTIONS.pool={}
   if attempt==retries-1:raise
   time.sleep(2**attempt)
 raise AssertionError('unreachable')

def fetch_archive(url,dest,retries=5):
 """Use system TLS/HTTP2 and retained Range progress for large public ZIPs."""
 headers=dest.with_suffix('.headers')
 for attempt in range(retries):
  if dest.exists() and dest.stat().st_size>MAX_DOWNLOAD:raise ValueError('partial archive exceeds safety bound')
  dns_file=OUT/'dns-resolution.json'
  dns=json.loads(dns_file.read_text()).get('hosts',{}) if dns_file.exists() else {}
  host=urllib.parse.urlsplit(url).hostname;addresses=dns.get(host,{}).get('ipv4',[])
  resolve=['--resolve',host+':443:'+','.join(addresses)] if addresses else []
  command=['curl',*resolve,'--silent','--show-error','--location','--fail','--continue-at','-',
   '--connect-timeout','15','--max-time','90','--max-filesize',str(MAX_DOWNLOAD),
   '--dump-header',str(headers),'--output',str(dest),'--write-out','%{http_code}',url]
  completed=subprocess.run(command,capture_output=True,timeout=100)
  status=int(completed.stdout.decode().strip() or '0')
  raw_headers=headers.read_text(errors='replace') if headers.exists() else ''
  headers.unlink(missing_ok=True)
  if completed.returncode==0:
   if dest.stat().st_size>MAX_DOWNLOAD:raise ValueError('archive exceeds safety bound')
   return dest.stat().st_size
  if status==416:
   if dest.exists() and zipfile.is_zipfile(dest):return dest.stat().st_size
   dest.unlink(missing_ok=True)
  if status in (403,404,410):raise urllib.error.HTTPError(url,status,'public archive unavailable',{},None)
  if attempt==retries-1:
   raise RuntimeError('curl '+str(completed.returncode)+' HTTP '+str(status)+': '+completed.stderr.decode(errors='replace')[-400:])
  delay=2**attempt
  if status in (429,503):
   matches=re.findall(r'(?im)^retry-after:\s*(.+?)\r?$',raw_headers)
   if matches:
    try:delay=max(delay,float(matches[-1]))
    except ValueError:
     try:delay=max(delay,(email.utils.parsedate_to_datetime(matches[-1])-datetime.datetime.now(datetime.timezone.utc)).total_seconds())
     except (ValueError,TypeError):pass
  while delay>0:
   step=min(delay,60);time.sleep(step);delay-=step
 raise AssertionError('unreachable')

def reuse_previous():
 src=ROOT/'research/2026-10-19-release-review/source-audit.json'
 if not src.exists():return 0
 reused=0
 for x in json.loads(src.read_text()):
  if x.get('status')!='ok' or not x.get('evidence_file'):continue
  p=ROOT/x['evidence_file'];target=CACHE/(key(x['name'],x['version'])+'.zip')
  if target.exists():continue
  if p.is_file() and sha_file(p)==x.get('sha256'):
   shutil.copyfile(p,target);reused+=1
 return reused

def classify(txt):
 kinds=[k for k,r in {**EXACT,**NEAR}.items() if r.search(txt)]
 if 'ieee1588_context' in kinds and not re.search(r'(?i)ieee|ptp|clock|time|协议|同步|1588[-:]20(?:02|08|19)',txt):kinds.remove('ieee1588_context')
 return kinds

def excerpt(txt,kinds):
 matches=[({**EXACT,**NEAR}[k].search(txt)) for k in kinds]
 first=min((m.start() for m in matches if m),default=0)
 start=max(0,first-160)
 return {'text':txt[start:start+800],'excerpt_start_column':start+1,'match_column':first+1}

def scan_archive(p):
 override_file=OUT/'encoding-overrides.json'
 overrides=json.loads(override_file.read_text()).get('overrides',{}).get(pathlib.Path(p).name,{}) if override_file.exists() else {}
 files=[];hits=[];limitations=[];text_bytes=0;expanded=0
 with zipfile.ZipFile(p) as z:
  members=z.infolist()
  if len(members)>MAX_MEMBERS:
   return {'files':[],'hits':[],'limitations':[f'archive member count {len(members)} > {MAX_MEMBERS}'],'status':'limited'}
  for m in members:
   if m.is_dir():continue
   if m.flag_bits&1:
    limitations.append({'path':m.filename,'reason':'encrypted member'});continue
   if m.file_size>MAX_MEMBER or expanded+m.file_size>MAX_EXPANDED:
    limitations.append({'path':m.filename,'reason':'uncompressed safety limit','bytes':m.file_size});continue
   expanded+=m.file_size
   ext=pathlib.PurePosixPath(m.filename).suffix.lower()
   known_text=ext in TEXT_EXT or pathlib.PurePosixPath(m.filename).name.lower() in {'license','readme','makefile','dockerfile','notice','authors','copying'}
   h=hashlib.sha256();rawbytes=0;is_text=known_text;line=0;pending='';file_hits=[];decode_errors=False
   with z.open(m) as f:
    first=f.read(64*1024)
    encoding=overrides.get(m.filename,{}).get('encoding') or ('utf-32' if first.startswith((b'\xff\xfe\x00\x00',b'\x00\x00\xfe\xff')) else 'utf-16' if first.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
    if not known_text and ext not in BINARY_EXT:
     try:
      codecs.getincrementaldecoder(encoding)(errors='strict').decode(first,final=False)
      is_text=encoding in ('utf-16','utf-32') or b'\0' not in first
     except UnicodeDecodeError:is_text=False
    if ext in BINARY_EXT or overrides.get(m.filename,{}).get('classification')=='binary-fixture':is_text=False
    decoder=codecs.getincrementaldecoder(encoding)(errors='replace')
    validator=codecs.getincrementaldecoder(encoding)(errors='strict')
    chunk=first
    while chunk:
     h.update(chunk);rawbytes+=len(chunk)
     if is_text:
      if validator is not None:
       try:validator.decode(chunk,final=False)
       except UnicodeDecodeError:decode_errors=True;validator=None
      pending+=decoder.decode(chunk,final=False)
      lines=pending.split('\n');pending=lines.pop()
      for txt in lines:
       line+=1
       kinds=classify(txt)
       if kinds:file_hits.append({'path':m.filename,'line':line,'kinds':kinds,**excerpt(txt,kinds)})
      # Every byte is still hashed. Keyword matching of a huge single line
      # uses overlapping character windows instead of truncating the file.
      if len(pending)>4*1024*1024:
       kinds=classify(pending)
       if kinds:file_hits.append({'path':m.filename,'line':line+1,'kinds':kinds,**excerpt(pending,kinds),'streamed_long_line':True,'byte_end':rawbytes})
       pending=pending[-4096:]
     chunk=f.read(1024*1024)
    if is_text:
     if validator is not None:
      try:validator.decode(b'',final=True)
      except UnicodeDecodeError:decode_errors=True
     pending+=decoder.decode(b'',final=True)
     if pending:
      line+=1;kinds=classify(pending)
      if kinds:file_hits.append({'path':m.filename,'line':line,'kinds':kinds,**excerpt(pending,kinds)})
   if is_text:
    text_bytes+=rawbytes;hits.extend(file_hits)
    if decode_errors:limitations.append({'path':m.filename,'reason':'text contains UTF decoding replacement; inspect original encoding before claiming complete textual coverage'})
   files.append({'path':m.filename,'bytes':rawbytes,'sha256':h.hexdigest(),'kind':'text' if is_text else 'binary','encoding':encoding if is_text else None,'encoding_basis':overrides.get(m.filename,{}).get('basis'),'classification':overrides.get(m.filename,{}).get('classification'),'decode_replacement':decode_errors})
 return {'files':files,'hits':hits,'text_files':sum(x['kind']=='text' for x in files),'text_bytes':text_bytes,'binary_files':sum(x['kind']=='binary' for x in files),'expanded_bytes':expanded,'limitations':limitations,'status':'limited' if limitations else 'ok'}

def run_one(module,force=False):
 name,version=module['name'],module['version'];ident=key(name,version);result_path=OUT/'results'/(ident+'.json')
 if result_path.exists() and not force:
  prior=json.loads(result_path.read_text())
  if prior.get('status')=='ok' and prior.get('scanner_version')==SCANNER_VERSION:return prior
 url='https://download.mooncakes.io/user/'+urllib.parse.quote(name,safe='/')+'/'+urllib.parse.quote(version,safe='')+'.zip'
 p=CACHE/(ident+'.zip');base={'scanner_version':SCANNER_VERSION,'scanner_sha256':SCANNER_SHA256,'name':name,'version':version,'yanked':module.get('yanked'),'repository':module.get('repository'),'url':url,'checked_at':now(),'cache_file':str(p),'evidence_file':str(p)}
 try:
  if p.exists() and not zipfile.is_zipfile(p):p.unlink()
  source='verified_local_cache' if p.exists() else 'official_download'
  if not p.exists():
   # The publisher's verified public 302 points to this CloudFront route with
   # the exact same /user/name/version.zip path. Bypass only that redundant
   # latency, preserving the official origin URL and fallback in the record.
   temp=p.with_suffix('.download');cdn_url=OFFICIAL_CDN+urllib.parse.urlsplit(url).path
   base['download_transport']='system-curl-with-range-resume';base['dns_evidence']='research/full-source-audit/dns-resolution.json';base['download_url']=cdn_url;base['download_route_evidence']='research/full-source-audit/download-route.json'
   try:fetch_archive(cdn_url,temp,retries=3)
   except Exception as cdn_error:
    base['cdn_fallback_reason']=type(cdn_error).__name__+': '+str(cdn_error)
    base['download_url']=url;fetch_archive(url,temp,retries=3)
   temp.replace(p)
  base.update(archive_bytes=p.stat().st_size,sha256=sha_file(p),source=source)
  base.update(scan_archive(p))
 except Exception as e:
  base.update(status='unavailable' if isinstance(e,urllib.error.HTTPError) and e.code in(403,404,410) else 'error',error=type(e).__name__+': '+str(e))
  if isinstance(e,urllib.error.HTTPError):base['http_status']=e.code
 atomic(result_path,base)
 return base

def manifest(modules,results,started,final=False):
 statuses={s:sum(x.get('status')==s for x in results.values()) for s in ('ok','limited','unavailable','error')}
 hit_modules=[{'name':x['name'],'version':x['version'],'result':'results/'+key(x['name'],x['version'])+'.json','kinds':sorted({k for h in x.get('hits',[]) for k in h['kinds']}),'hit_count':len(x.get('hits',[]))} for x in results.values() if x.get('hits')]
 out={'schema':'mooncakes-full-source-scan/v1','scanner_version':SCANNER_VERSION,'scanner_sha256':SCANNER_SHA256,'started_at':started,'updated_at':now(),'final':final,'index':json.loads((OUT/'index.json').read_text()),'scope':'Every module and listed current version in the captured official index, including yanked entries; not all historical versions. No code executed.','expected_modules':len(modules),'processed_modules':len(results),'statuses':statuses,'text_files':sum(x.get('text_files',0) for x in results.values()),'text_bytes':sum(x.get('text_bytes',0) for x in results.values()),'archive_bytes':sum(x.get('archive_bytes',0) for x in results.values()),'limits':{'archive_download_bytes':MAX_DOWNLOAD,'member_uncompressed_bytes':MAX_MEMBER,'archive_uncompressed_bytes':MAX_EXPANDED,'member_count':MAX_MEMBERS,'large_text':'streamed without per-text truncation; oversized single lines use rolling overlap'},'cache':str(CACHE),'prior_reused_index':'research/2026-10-19-release-review/source-audit.json','limitations':'Keyword inventory requires semantic review; common abstractions and absolute absence of all similarity cannot be proved by keyword scan. Limited/unavailable/error entries are explicitly not covered.','hit_modules':hit_modules,'unresolved':[{'name':x['name'],'version':x['version'],'status':x['status'],'error':x.get('error'),'limitations':x.get('limitations',[]),'repository':x.get('repository'),'result':'results/'+key(x['name'],x['version'])+'.json'} for x in results.values() if x.get('status')!='ok']}
 out['modules_json_sha256']=sha_file(OUT/'modules.json')
 out['expected_unique_name_versions']=len({(m['name'],m['version']) for m in modules})
 out['keyword_patterns']={k:r.pattern for k,r in {**EXACT,**NEAR}.items()}
 out['encoding_overrides_sha256']=sha_file(OUT/'encoding-overrides.json') if (OUT/'encoding-overrides.json').exists() else None
 if final:
  out['result_bindings']=[{'name':m['name'],'version':m['version'],'file':'results/'+key(m['name'],m['version'])+'.json','sha256':sha_file(OUT/'results'/(key(m['name'],m['version'])+'.json'))} for m in modules]
 atomic(OUT/'manifest.json',out)
 return out

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--workers',type=int,default=8);parser.add_argument('--refresh-index',action='store_true');parser.add_argument('--retry-failed',action='store_true');parser.add_argument('--force',action='store_true');parser.add_argument('--limit',type=int);args=parser.parse_args()
 OUT.mkdir(parents=True,exist_ok=True);CACHE.mkdir(parents=True,exist_ok=True)
 if args.refresh_index or not (OUT/'modules.json').exists():
  # Preserve the exact fetched JSON body before parsing or pretty printing.
  # Accept-Encoding identity keeps these raw representation bytes independently
  # hashable; TLS verification stays enabled and no authorization is used.
  raw_path=OUT/'modules-response.raw.json';headers_path=OUT/'modules-response.headers.txt'
  command=['curl','--silent','--show-error','--location','--fail','--header','Accept-Encoding: identity','--connect-timeout','20','--max-time','180','--retry','3','--dump-header',str(headers_path),'--output',str(raw_path),INDEX_URL]
  completed=subprocess.run(command,capture_output=True,timeout=600)
  if completed.returncode:raise RuntimeError(completed.stderr.decode(errors='replace')[-800:])
  b=raw_path.read_bytes();modules=json.loads(b)
  atomic(OUT/'modules.json',modules);atomic(OUT/'index.json',{'url':INDEX_URL,'retrieved_at':now(),'raw_sha256':hashlib.sha256(b).hexdigest(),'raw_body_file':'modules-response.raw.json','headers_file':'modules-response.headers.txt','modules_json_sha256':sha_file(OUT/'modules.json'),'count':len(modules),'unique_name_versions':len({(m['name'],m['version']) for m in modules})})
 modules=json.loads((OUT/'modules.json').read_text());started=now();reused=reuse_previous();results={}
 # Resolve each publisher host once, retaining TLS verification. Independent
 # curl processes otherwise saturate the macOS resolver under concurrency.
 dns={}
 for host in ('d15l9c1mnzh3r.cloudfront.net','download.mooncakes.io'):
  try:dns[host]={'ipv4':sorted({x[4][0] for x in socket.getaddrinfo(host,443,socket.AF_INET,socket.SOCK_STREAM)})}
  except OSError as e:dns[host]={'error':str(e),'ipv4':[]}
 atomic(OUT/'dns-resolution.json',{'resolved_at':now(),'hosts':dns,'purpose':'Public system DNS results reused by curl --resolve; normal TLS hostname/certificate verification remains enabled.'})
 for m in modules:
  p=OUT/'results'/(key(m['name'],m['version'])+'.json')
  if p.exists():
   x=json.loads(p.read_text())
   if not args.force and x.get('scanner_version')==SCANNER_VERSION and (x.get('status')=='ok' or not args.retry_failed):results[(m['name'],m['version'])]=x
 todo=[m for m in modules if (m['name'],m['version']) not in results]
 # Review likely neighbors and verified archives early without changing the
 # final all-index scope. This lets semantic review run during the long scan.
 priority=re.compile(r'(?i)ptp|1588|bmca|clock|ntp|sync|protocol|packet|pcap|trace|audit|deadline|timeout|correlat|时钟|同步|协议|报文|审计|观察|窗口')
 todo.sort(key=lambda m:(not (CACHE/(key(m['name'],m['version'])+'.zip')).exists(),not bool(priority.search(json.dumps(m,ensure_ascii=False))),m['name']))
 if args.limit:todo=todo[:args.limit]
 print(json.dumps({'index_count':len(modules),'reused_archives':reused,'resumed_results':len(results),'todo':len(todo),'cache':str(CACHE)}),flush=True)
 manifest(modules,results,started)
 with concurrent.futures.ThreadPoolExecutor(max_workers=max(1,min(args.workers,24))) as pool:
  jobs={pool.submit(run_one,m,args.force):m for m in todo}
  for n,future in enumerate(concurrent.futures.as_completed(jobs),1):
   m=jobs[future];x=future.result();results[(m['name'],m['version'])]=x
   if n%25==0 or n==len(todo):
    snap=manifest(modules,results,started,final=n==len(todo) and len(results)==len(modules))
    print(json.dumps({'processed':len(results),'expected':len(modules),'statuses':snap['statuses'],'text_files':snap['text_files'],'hit_modules':len(snap['hit_modules']),'latest':m['name']}),flush=True)
 snap=manifest(modules,results,started,final=len(results)==len(modules))
 print(json.dumps({'complete':snap['final'],'statuses':snap['statuses'],'unresolved':len(snap['unresolved'])}),flush=True)

if __name__=='__main__':main()
