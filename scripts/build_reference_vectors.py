#!/usr/bin/env python3
"""Compile frozen LinuxPTP C comparison functions as a separate GPL test oracle.
Generated vectors are data, not a translation or copy of the oracle into the product.
"""
import copy, json, random, subprocess, tempfile, os, hashlib, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];REF=ROOT/'research/implementation-reference'
source=(REF/'linuxptp-v4.4-bmc.c').read_text()
functions=source[source.index('static int portid_cmp'):source.index('enum port_state bmc_state_decision')]
assert 'int dscmp(' in functions and 'int dscmp2(' in functions
# Minimal host-order data structures expose only fields used by the original functions.
preamble='''#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define A_BETTER_TOPO 2
#define A_BETTER 1
#define B_BETTER -1
#define B_BETTER_TOPO -2
struct ClockIdentity { unsigned char id[8]; };
struct PortIdentity { struct ClockIdentity clockIdentity; int portNumber; };
struct ClockQuality { int clockClass, clockAccuracy, offsetScaledLogVariance; };
struct dataset { struct ClockIdentity identity; int priority1; struct ClockQuality quality; int priority2; unsigned int stepsRemoved; struct PortIdentity sender, receiver; };
'''
base={'grandmaster':'0000000000000010','priority1':128,'clock_class':248,'accuracy':34,'variance':17185,'priority2':128,'steps_removed':2,'sender_clock':'0000000000000020','sender_port':1,'receiver_clock':'0000000000000080','receiver_port':1}
rows=[]
def add(name,a,b,rule=None):rows.append({'name':name,'a':a.copy(),'b':b.copy(),'rule':rule})
for field,rule in [('priority1','priority1'),('clock_class','clockClass'),('accuracy','clockAccuracy'),('variance','offsetScaledLogVariance'),('priority2','priority2')]:
 a=dict(base,grandmaster='0000000000000010');b=dict(base,grandmaster='0000000000000011');a[field]=0;b[field]=65535 if field=='variance' else 255
 add('different-'+field,a,b,'BMCA.DIFFERENT_GM.'+rule);add('reverse-'+field,b,a,'BMCA.DIFFERENT_GM.'+rule)
a=base.copy();b=dict(base,grandmaster='0000000000000011');add('gm-id',a,b,'BMCA.DIFFERENT_GM.identity');add('gm-id-reverse',b,a,'BMCA.DIFFERENT_GM.identity')
for asteps,bsteps in [(0,254),(254,0)]:add('far-hops',dict(base,steps_removed=asteps),dict(base,steps_removed=bsteps),'BMCA.SAME_GM.stepsRemoved')
for reverse in [False,True]:
 for sender in ['0000000000000070','0000000000000080','0000000000000090']:
  a=dict(base,steps_removed=1);b=dict(base,steps_removed=2,sender_clock=sender)
  if reverse:a,b=b,a
  add('one-hop-'+str(reverse)+'-'+sender,a,b,'BMCA.SAME_GM.'+('error1' if sender=='0000000000000080' else 'oneHop'))
for field,value,rule in [('sender_clock','0000000000000021','sender'),('sender_port',2,'sender'),('receiver_port',2,'receiverPort')]:
 a=base.copy();b=dict(base,**{field:value});add(field,a,b,'BMCA.SAME_GM.'+rule);add(field+'-reverse',b,a,'BMCA.SAME_GM.'+rule)
add('error2',base,base,'BMCA.SAME_GM.error2')
rng=random.Random(15882008)
for i in range(192):
 a=base.copy();b=base.copy()
 if i%2:
  for c in [a,b]:
   c.update(grandmaster=f'{rng.randrange(1,256):016x}',priority1=rng.randrange(256),clock_class=rng.randrange(256),accuracy=rng.randrange(256),variance=rng.randrange(65536),priority2=rng.randrange(256))
 else:
  for c in [a,b]:c.update(steps_removed=rng.randrange(8),sender_clock=f'{rng.randrange(0x60,0xa0):016x}',sender_port=rng.randrange(1,5),receiver_port=rng.randrange(1,5))
 add(f'random-{i}',a,b)
def c_identity(s):return '{{'+','.join(str(x) for x in bytes.fromhex(s))+'}}'
def init(d):
 return '{'+','.join([c_identity(d['grandmaster']),str(d['priority1']),'{'+','.join(str(d[k]) for k in ['clock_class','accuracy','variance'])+'}',str(d['priority2']),str(d['steps_removed']),'{'+c_identity(d['sender_clock'])+','+str(d['sender_port'])+'}','{'+c_identity(d['receiver_clock'])+','+str(d['receiver_port'])+'}'])+'}'
statements=['int main(void){']
for i,row in enumerate(rows):statements.append('{struct dataset a='+init(row['a'])+', b='+init(row['b'])+'; printf("%d\\n",dscmp(&a,&b));}')
statements.append('return 0;}')
oracle=preamble+functions+'\n'+'\n'.join(statements)
# GPL attribution/license remains together with any saved extracted harness.
(REF/'bmca-oracle.c').write_text(source[:source.index('#include')]+preamble+functions+'\n'+'\n'.join(statements)+'\n')
env=os.environ.copy()
if os.uname().sysname=='Darwin':
 env['SDKROOT']='/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk'
with tempfile.TemporaryDirectory(prefix='ptp-oracle-') as d:
 c=Path(d)/'oracle.c';exe=Path(d)/'oracle';c.write_text(oracle)
 subprocess.run(['cc','-std=c11','-O2',str(c),'-o',str(exe)],check=True,env=env)
 results=list(map(int,subprocess.check_output([str(exe)],text=True).splitlines()))
assert len(results)==len(rows)
def mb(c,cid,frame):
 return '{id:'+json.dumps(cid)+',frame:'+str(frame)+',domain:0,data:{origin:{seconds:0L,nanos:0},utc_offset:37,'+','.join(k+':'+(json.dumps(c[k]) if isinstance(c[k],str) else str(c[k])) for k in ['priority1','clock_class','accuracy','variance','priority2','grandmaster','steps_removed'])+',time_source:160},sender:{clock:'+json.dumps(c['sender_clock'])+',port:'+str(c['sender_port'])+'},receiver:{clock:'+json.dumps(c['receiver_clock'])+',port:'+str(c['receiver_port'])+'}}'
code=['// Generated independent LinuxPTP v4.4 oracle vectors; see scripts/build_reference_vectors.py.']
for i,(row,result) in enumerate(zip(rows,results)):
 row.update(oracle_result=result,side=-1 if result>0 else (1 if result<0 else 0),topology=abs(result)==2)
 code+=['///|',f'test "LinuxPTP vector {i} {row["name"]}" {{',f'  let a : @bmca.Candidate={mb(row["a"],"A",1)}',f'  let b : @bmca.Candidate={mb(row["b"],"B",2)}','  let r=@bmca.compare(a,b)',f'  assert_eq(r.side,{row["side"]})',f'  assert_eq(r.topology,{str(row["topology"]).lower()})',f'  assert_eq(r.status.label(),"{"Unsupported" if result==0 else "Pass"}")']
 if row['rule']:code.append(f'  assert_eq(r.rule,"{row["rule"]}")')
 code+=['}']
(ROOT/'tests/reference_test.mbt').write_text('\n'.join(code)+'\n')
(REF/'bmca-vectors.json').write_text(json.dumps({'upstream_tag':'v4.4','oracle_source_sha256':hashlib.sha256((REF/'linuxptp-v4.4-bmc.c').read_bytes()).hexdigest(),'vector_count':len(rows),'seed':15882008,'vectors':rows},indent=2)+'\n')
print('Independent C reference vectors:',len(rows),'results:',{n:results.count(n) for n in sorted(set(results))})
