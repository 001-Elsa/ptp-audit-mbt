#!/usr/bin/env python3
"""Independent struct/Fraction fixtures; never imports or calls the MoonBit implementation."""
import copy, json, struct, hashlib, itertools
from pathlib import Path
from fractions import Fraction
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'fixtures'; OUT.mkdir(exist_ok=True)
MASTER='0011223344556677'; SLAVE='8899aabbccddeeff'; OTHER='0011223344556678'
def port(clock=MASTER, number=1): return {'clock':clock,'port':number}
def identity(p):return bytes.fromhex(p['clock'])+struct.pack('>H',p['port'])
def timestamp(sec=100, ns=0):return sec.to_bytes(6,'big')+struct.pack('>I',ns)
def payload(kind, seq=7, source=None, domain=0, flags=0, correction=0, sec=100, ns=0, requester=None, announce=None):
 source=source or port(); n={0:44,8:44,1:44,9:54,11:64}[kind]
 header=struct.pack('>BBHBBHqI',kind,2,n,domain,0,flags,correction,0)+identity(source)+struct.pack('>HBb',seq,{0:0,8:2,1:1,9:3,11:5}[kind],0)
 body=timestamp(sec,ns)
 if kind==9:body+=identity(requester or port(SLAVE))
 if kind==11:
  a={'priority1':128,'clock_class':248,'accuracy':0x22,'variance':0x4321,'priority2':128,'grandmaster':MASTER,'steps_removed':0,'time_source':0xa0,**(announce or {})}
  body+=struct.pack('>hBBBBHB',37,0,a['priority1'],a['clock_class'],a['accuracy'],a['variance'],a['priority2'])+bytes.fromhex(a['grandmaster'])+struct.pack('>HB',a['steps_removed'],a['time_source'])
 assert len(header+body)==n
 return (header+body).hex()
def frame(i,kind,**kw):
 sec=kw.get('sec',100); ns=kw.get('ns',0)
 return {'id':i,'epoch':0,'payload_hex':payload(kind,**kw),'window':'capture-0','capture_time':{'seconds':str(sec),'nanos':ns},'capture_clock_domain':'slave-monotonic-0'}
def observation(frames):
 seconds=[int(f.get('capture_time',{}).get('seconds','100')) for f in frames] or [100]
 start=max(0,min(seconds)-1);end=min((1<<48)-1,max(seconds)+1)
 return {'windows':[{'id':'capture-0','epoch':0,'clock_domain':'slave-monotonic-0','start':{'seconds':str(start),'nanos':0},'end':{'seconds':str(end),'nanos':999999999},'complete':True}], 'policy':{'source':'fixture-analysis-policy','sync_follow_up_ns':1000000000,'delay_response_ns':1000000000}}
def case(frames):
 return {'schema':'ptp-audit/v1','profile':'default-e2e-two-step-2008','frames':frames,'observation':observation(frames)}
def full(sec=100):
 c=case([frame(1,0,flags=512,correction=-32768,sec=sec),frame(2,8,correction=16384,sec=sec,ns=1000),frame(3,1,seq=31,source=port(SLAVE),correction=999999,sec=sec,ns=5000),frame(4,9,seq=31,requester=port(SLAVE),correction=49152,sec=sec,ns=5250)])
 c['frames'][0].update(local_port=port(SLAVE),event_time={'seconds':str(sec),'nanos':1300},clock_domain='slave-monotonic-0',direction='rx')
 c['frames'][2].update(local_port=port(SLAVE),event_time={'seconds':str(sec),'nanos':5000},clock_domain='slave-monotonic-0',direction='tx')
 c['pair_claims']=[{'sync':1,'follow_up':2}];c['exchanges']=[{'sync':1,'follow_up':2,'delay_req':3,'delay_resp':4}]
 c['assumptions']={'symmetric_path':True,'timestamp_provenance':True,'stable_rates':True}
 return c
# The Delay_Resp correction already includes request-path correction: request is deliberately nonzero.
fwd=Fraction(1300-1000)-Fraction(-32768+16384,65536);rev=Fraction(5250-5000)-Fraction(49152,65536)
measurement={'offset_numerator':str(int((fwd-rev)*65536)),'mean_delay_numerator':str(int((fwd+rev)*65536)),'denominator':131072}
rows=[]
def save(name,c,status,rule=None,measure=None,note='Constructed from independent network-order fields; not a physical capture.'):
 path=OUT/(name+'.json');path.write_text(json.dumps(c,ensure_ascii=False,indent=2)+'\n')
 rows.append({'name':name,'path':'fixtures/'+name+'.json','status':status,'rule':rule,'measurement':measure,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'provenance':note})
save('complete-exchange',full(),'Pass','MEASUREMENT.E2E',measurement)
save('large-48bit-seconds',full((1<<48)-1),'Pass','MEASUREMENT.E2E',measurement)
c=full();c['frames']=[c['frames'][1],c['frames'][3],c['frames'][0],c['frames'][2]];save('reordered-exchange',c,'Pass','MEASUREMENT.E2E',measurement)
c=full();del c['frames'][0]['event_time'];save('missing-rx-time',c,'InsufficientEvidence','MEASUREMENT.EVIDENCE')
for field in ['symmetric_path','timestamp_provenance','stable_rates']:
 c=full();c['assumptions'][field]=False;save('missing-'+field,c,'InsufficientEvidence','MEASUREMENT.EVIDENCE')
c=full();c['frames'][2]['clock_domain']='different-clock';save('different-clock-domains',c,'InsufficientEvidence','MEASUREMENT.EVIDENCE')
c=full();c['frames'][0]['event_time']['nanos']=0;save('negative-inferred-delay',c,'InsufficientEvidence','MEASUREMENT.PATH_ASSUMPTIONS')
c=full();c['frames']=c['frames'][:3];save('truncated-capture',c,'InsufficientEvidence','CLAIM.MISSING_FRAME')
for name,index,kw in [('wrong-follow-up-source',1,dict(source=port(OTHER))),('wrong-follow-up-domain',1,dict(domain=1)),('wrong-response-requester',3,dict(requester=port(OTHER))),('wrong-response-master',3,dict(source=port(OTHER))),('wrong-response-sequence',3,dict(seq=30))]:
 c=full();kind=8 if index==1 else 9;defaults=dict(sec=100,ns=1000) if index==1 else dict(seq=31,ns=5250,requester=port(SLAVE))
 defaults.update(kw);c['frames'][index]['payload_hex']=payload(kind,**defaults);save(name,c,'Violation','CLAIM.SYNC_FOLLOW_UP' if index==1 else 'CLAIM.E2E_IDENTITY')
c=full();c['frames'][3]['epoch']=1;save('master-change-epoch',c,'InsufficientEvidence','CLAIM.DELAY_WINDOW')
c=full();c['frames'].append(dict(c['frames'][0],id=10));save('duplicate-sync',c,'InsufficientEvidence','EXCHANGE.SYNC_FOLLOW_UP')
c=full();c['frames'].append(dict(c['frames'][1],id=10));save('duplicate-follow-up',c,'InsufficientEvidence','EXCHANGE.SYNC_FOLLOW_UP')
c=full();c['frames'].append(dict(c['frames'][2],id=10));save('duplicate-delay-request',c,'InsufficientEvidence','MEASUREMENT.AMBIGUOUS')
c=full();c['frames'].append(dict(c['frames'][3],id=10));save('duplicate-delay-response',c,'InsufficientEvidence','MEASUREMENT.AMBIGUOUS')
c=case([frame(1,0,flags=512),frame(2,8,source=port(OTHER))]);save('unclaimed-different-source',c,'InsufficientEvidence','EXCHANGE.ORPHAN_FOLLOW_UP')
c=case([frame(1,0,flags=512,seq=65535),frame(2,8,seq=65535),frame(3,0,flags=512,seq=0),frame(4,8,seq=0)]);save('sequence-wrap',c,'Pass','EXCHANGE.SYNC_FOLLOW_UP')
c=case([frame(1,0,flags=512),frame(2,8),frame(3,0,flags=512,source=port(OTHER)),frame(4,8,source=port(OTHER)),frame(5,0,flags=512,domain=2),frame(6,8,domain=2)]);save('interleaved-sources-domains',c,'Pass','EXCHANGE.SYNC_FOLLOW_UP')
c=case([frame(1,0)]);save('single-step',c,'Unsupported','SCOPE.TWO_STEP')
c=case([]);c['profile']='802.1AS';save('unsupported-profile',c,'Unsupported','SCOPE.CASE')
c=case([frame(1,0,flags=512)]);b=bytearray.fromhex(c['frames'][0]['payload_hex']);b+=b'\0\0\0\0';b[2:4]=len(b).to_bytes(2,'big');c['frames'][0]['payload_hex']=b.hex();save('unknown-tlv',c,'Unsupported','SCOPE.TLV')
for name,offset,data,rule in [('bad-length',3,b'\x2b','WIRE.MESSAGE_LENGTH'),('bad-nanoseconds',40,(1000000000).to_bytes(4,'big'),'WIRE.NANOSECONDS'),('bad-reserved',5,b'\x01','WIRE.RESERVED'),('bad-control',32,b'\x05','WIRE.CONTROL'),('bad-source-port',28,b'\0\0','WIRE.SOURCE_PORT')]:
 c=case([frame(1,0,flags=512)]);b=bytearray.fromhex(c['frames'][0]['payload_hex']);b[offset:offset+len(data)]=data;c['frames'][0]['payload_hex']=b.hex();save(name,c,'Violation',rule)
c=case([frame(1,8)]);c['frames'][0]['payload_hex']='zz';save('nonhex',c,'Violation','WIRE.HEX')
c=case([frame(1,8)]);c['frames'].append(c['frames'][0]);save('duplicate-frame-id',c,'Violation','INPUT.SCHEMA')
c=case([]);c['unexpected']=1;save('unknown-schema-key',c,'Violation','INPUT.SCHEMA')
c=case([{'id':i,'payload_hex':''} for i in range(257)]);save('frame-budget',c,'Violation','INPUT.SCHEMA')
# Whole audit: complete exchange plus Announce snapshot with a real declared choice.
c=full();c['frames'] += [frame(5,11,announce={'priority1':100}),frame(6,11,source=port(OTHER),announce={'grandmaster':OTHER,'priority1':120})];c['bmca']={'candidates':[{'id':'A','frame':5,'receiver':port(SLAVE)},{'id':'B','frame':6,'receiver':port(SLAVE)}],'selected':'A','candidates_complete':True,'eligibility_confirmed':True,'snapshot':{'epoch':0,'window':'capture-0','clock_domain':'slave-monotonic-0','decision_time':{'seconds':'100','nanos':10000},'announce_validity_ns':1000000000,'validity_source':'fixture-declared-observation-window','validity_confirmed':True,'capture_window_confirmed':True}};save('complete-audit',c,'Pass','BMCA.OBSERVED_DECISION',measurement)
# Deterministic BMCA branch fixtures. All receiver clocks refer to the same observing clock.
def bmcase(a,b,selected='A',sa=None,sb=None,ra=None,rb=None):
 c=case([frame(1,11,source=sa or port(),announce=a),frame(2,11,source=sb or port(OTHER),announce=b)])
 c['bmca']={'candidates':[{'id':'A','frame':1,'receiver':ra or port(SLAVE)},{'id':'B','frame':2,'receiver':rb or port(SLAVE)}],'selected':selected,'candidates_complete':True,'eligibility_confirmed':True,'snapshot':{'epoch':0,'window':'capture-0','clock_domain':'slave-monotonic-0','decision_time':{'seconds':'100','nanos':10000},'announce_validity_ns':1000000000,'validity_source':'fixture-declared-observation-window','validity_confirmed':True,'capture_window_confirmed':True}};return c
names={'priority1':'priority1','clock_class':'clockClass','accuracy':'clockAccuracy','variance':'offsetScaledLogVariance','priority2':'priority2'}
for field,rule in names.items():
 c=bmcase({field:1},{'grandmaster':OTHER,field:2});save('bmca-'+field,c,'Pass','BMCA.DIFFERENT_GM.'+rule)
c=bmcase({}, {'grandmaster':OTHER});save('bmca-identity',c,'Pass','BMCA.DIFFERENT_GM.identity')
c=bmcase({'priority1':1},{'grandmaster':OTHER,'priority1':2},'B');save('bmca-wrong-selection',c,'Violation','BMCA.OBSERVED_DECISION')
c=bmcase({'steps_removed':1},{'steps_removed':4});save('bmca-steps',c,'Pass','BMCA.SAME_GM.stepsRemoved')
c=bmcase({'steps_removed':1},{'steps_removed':2});save('bmca-one-hop-topology',c,'Pass','BMCA.SAME_GM.oneHop')
c=bmcase({'steps_removed':1},{'steps_removed':2},sb=port('ffffffffffffffff'));save('bmca-one-hop-ordinary',c,'Pass','BMCA.SAME_GM.oneHop')
c=bmcase({'steps_removed':1},{'steps_removed':2},sb=port(SLAVE));save('bmca-error1',c,'Unsupported','BMCA.SAME_GM.error1')
c=bmcase({},{});save('bmca-sender-identity',c,'Pass','BMCA.SAME_GM.sender')
c=bmcase({},{},sa=port(MASTER,1),sb=port(MASTER,2));save('bmca-sender-port',c,'Pass','BMCA.SAME_GM.sender')
c=bmcase({},{},sa=port(),sb=port(),ra=port(SLAVE,1),rb=port(SLAVE,2));save('bmca-receiver-port',c,'Pass','BMCA.SAME_GM.receiverPort')
c=bmcase({},{},sa=port(),sb=port());save('bmca-error2',c,'Unsupported','BMCA.SAME_GM.error2')
c=bmcase({'steps_removed':255},{});save('bmca-steps-out-of-scope',c,'Unsupported','BMCA.SCOPE.DATASET')
for name,mut in [('incomplete-candidates',lambda b:b.update(candidates_complete=False)),('unqualified-candidates',lambda b:b.update(eligibility_confirmed=False)),('no-observed-selection',lambda b:b.pop('selected')),('missing-candidate-frame',lambda b:b['candidates'].append({'id':'C','frame':99,'receiver':port(SLAVE)}))]:
 c=bmcase({}, {'grandmaster':OTHER});mut(c['bmca']);save('bmca-'+name,c,'InsufficientEvidence','BMCA.MISSING_FRAME' if name=='missing-candidate-frame' else ('BMCA.OBSERVED_DECISION' if name=='no-observed-selection' else 'BMCA.EVIDENCE'))
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['candidates'][1]['receiver']=port('ffffffffffffffff');save('bmca-mixed-receiver',c,'Unsupported','BMCA.SCOPE.CONTEXT')
c=case([]);c['bmca']={'candidates':[],'candidates_complete':True,'eligibility_confirmed':True};save('bmca-empty',c,'InsufficientEvidence','BMCA.EVIDENCE')
# Observation regressions: missing premises can never manufacture a measurement.
for field in ['epoch','window','capture_time','capture_clock_domain']:
 c=full()
 for f in c['frames']:f.pop(field)
 save('missing-all-'+field.replace('_','-'),c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['frames'][1].pop('epoch');save('missing-one-epoch',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c.pop('observation');save('missing-observation',c,'InsufficientEvidence','OBSERVATION.WINDOW')
c=full();c['observation'].pop('policy');save('missing-deadline-policy',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['observation']['windows'][0]['complete']=False;save('incomplete-capture-window',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['observation']['windows'][0]['end']={'seconds':'98','nanos':0};save('reversed-capture-window',c,'InsufficientEvidence','OBSERVATION.WINDOW')
c=full();c['frames'][0]['capture_time']={'seconds':'98','nanos':0};save('frame-outside-capture-window',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['frames'][1]['capture_clock_domain']='another-capture-clock';save('mixed-capture-clock',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['observation']['policy']['sync_follow_up_ns']=999;save('follow-up-after-budget',c,'InsufficientEvidence','CLAIM.SYNC_WINDOW')
c=full();c['observation']['policy']['delay_response_ns']=249;save('delay-response-after-budget',c,'InsufficientEvidence','CLAIM.DELAY_WINDOW')
c=full();c['observation']['policy']['sync_follow_up_ns']=1000;c['observation']['policy']['delay_response_ns']=6000;save('follow-up-at-budget',c,'Pass','MEASUREMENT.E2E',measurement)
c=full();c['observation']['policy']['sync_follow_up_ns']='9223372036854775807';c['observation']['policy']['delay_response_ns']='5000000000';save('int64-decimal-budgets',c,'Pass','MEASUREMENT.E2E',measurement)
for value in ['9223372036854775808','-1','1.5','']:
 c=full();c['observation']['policy']['sync_follow_up_ns']=value;save('invalid-budget-'+str(len(rows)),c,'Violation','INPUT.SCHEMA')
for name,end,complete,rule in [('expired',{'seconds':'101','nanos':0},True,'EXCHANGE.STATE.EVICTED'),('before-deadline',{'seconds':'100','nanos':999999999},True,'EXCHANGE.STATE.PENDING'),('capture-gap',{'seconds':'101','nanos':0},False,'EXCHANGE.STATE.PENDING')]:
 c=case([frame(1,0,flags=512)]);c['observation']['windows'][0].update(end=end,complete=complete)
 save('missing-follow-up-'+name,c,'InsufficientEvidence',rule)
# BMCA must be one current observation snapshot; never compare stale/mixed epochs.
for name,field,value in [('mixed-epoch','epoch',1),('mixed-window','window','another-window'),('mixed-clock','capture_clock_domain','another-clock')]:
 c=bmcase({}, {'grandmaster':OTHER});c['frames'][1][field]=value;save('bmca-'+name,c,'InsufficientEvidence','BMCA.SNAPSHOT.WINDOW')
c=bmcase({}, {'grandmaster':OTHER});c['bmca'].pop('snapshot');save('bmca-missing-snapshot',c,'InsufficientEvidence','BMCA.SNAPSHOT.EVIDENCE')
for key in ['epoch','window','clock_domain','decision_time','announce_validity_ns','validity_source']:
 c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot'].pop(key);save('bmca-missing-'+key.replace('_','-'),c,'InsufficientEvidence','BMCA.SNAPSHOT.EVIDENCE')
for key in ['validity_confirmed','capture_window_confirmed']:
 c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot'][key]=False;save('bmca-unconfirmed-'+key.replace('_','-'),c,'InsufficientEvidence','BMCA.SNAPSHOT.EVIDENCE')
c=bmcase({}, {'grandmaster':OTHER});c['frames'][1]['capture_time']['nanos']=20000;save('bmca-future-announce',c,'InsufficientEvidence','BMCA.SNAPSHOT.EXPIRED')
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot']['decision_time']={'seconds':'102','nanos':1};c['observation']['windows'][0]['end']={'seconds':'103','nanos':0};save('bmca-stale-announce',c,'InsufficientEvidence','BMCA.SNAPSHOT.WINDOW')
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot']['decision_time']={'seconds':'102','nanos':1};save('bmca-decision-outside-window',c,'InsufficientEvidence','BMCA.SNAPSHOT.WINDOW')
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot']['typo']=True;save('bmca-unknown-snapshot-field',c,'Violation','INPUT.SCHEMA')
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot']=None;save('bmca-null-snapshot',c,'Violation','INPUT.SCHEMA')
# Three candidates, every input order: all compare steps must still choose A.
for i,order in enumerate(itertools.permutations(range(3))):
 c=bmcase({'priority1':1},{'grandmaster':OTHER,'priority1':2})
 c['frames'].append(frame(3,11,source=port('0011223344556679'),announce={'grandmaster':'0011223344556679','priority1':3}))
 candidates=c['bmca']['candidates']+[{'id':'C','frame':3,'receiver':port(SLAVE)}]
 c['bmca']['candidates']=[candidates[j] for j in order];save('bmca-three-permutation-'+str(i+1),c,'Pass','BMCA.OBSERVED_DECISION')
# Conservative unsupported correction encodings from conflicting official interpretations.
for name,value in [('all-ones',-1),('int64-max',9223372036854775807)]:
 c=case([frame(1,8,correction=value)]);save('correction-too-big-'+name,c,'Unsupported','SCOPE.CORRECTION_TOO_BIG')
for kind in [8,1,9,11]:
 c=case([frame(1,kind,flags=512)]);save('two-step-flag-nonsync-'+str(kind),c,'Violation','WIRE.TWO_STEP_FLAG')

# Independent review regressions: metadata labels, unused fields and claim ambiguity.
c=full();c['frames'][0]['clock_domain']='   ';c['frames'][2]['clock_domain']='   ';save('blank-event-clock-domain',c,'InsufficientEvidence','MEASUREMENT.EVIDENCE')
c=bmcase({}, {'grandmaster':OTHER});c['bmca']['snapshot']['validity_source']='   ';save('blank-bmca-validity-source',c,'InsufficientEvidence','BMCA.SNAPSHOT.EVIDENCE')
c=bmcase({}, {'grandmaster':OTHER});c['assumptions']={'symmetric_path':'yes'};save('bmca-unused-invalid-assumption',c,'Violation','INPUT.SCHEMA')
c=full();c['exchanges'].append(copy.deepcopy(c['exchanges'][0]));save('duplicate-exchange-claims',c,'InsufficientEvidence','CLAIM.AMBIGUOUS')
c=full();c['exchanges'].append(dict(c['exchanges'][0],delay_resp=99));save('conflicting-exchange-claims',c,'InsufficientEvidence','CLAIM.AMBIGUOUS')

# Keep previous simple examples represented in the verification manifest.
for name in ['schema-invalid','wire-only']:
 text=(OUT/(name+'.json')).read_text();rows.append({'name':name,'path':'fixtures/'+name+'.json','status':'Violation' if name=='schema-invalid' else 'InsufficientEvidence','rule':'INPUT.SCHEMA' if name=='schema-invalid' else 'SCOPE.NO_SEMANTIC_CHECK','measurement':None,'sha256':hashlib.sha256(text.encode()).hexdigest(),'provenance':'Minimal input boundary case.'})
(OUT/'manifest.json').write_text(json.dumps({'generator':'scripts/build_acceptance_fixtures.py','measurement_reference':{'forward_ns':str(fwd),'reverse_ns':str(rev),'offset_ns':str((fwd-rev)/2),'mean_delay_ns':str((fwd+rev)/2)},'cases':rows},ensure_ascii=False,indent=2)+'\n')
# Freeze actual fixture text into portable MoonBit tests. The CLI harness also reads the files to check sync.
code=['// Generated by scripts/build_acceptance_fixtures.py; independent Python struct/Fraction inputs.']
for row in rows:
 text=(ROOT/row['path']).read_text();literal=json.dumps(text,ensure_ascii=True)
 code += ['///|',f'test "fixture {row["name"]}" {{',f'  let r=@audit.audit({literal})',f'  assert_eq(r.status().label(),"{row["status"]}")',f'  assert_true(r.findings.any(fn(f) {{ f.rule=="{row["rule"]}" }}))']
 if row['measurement']:
  m=row['measurement'];code += ['  assert_eq(r.measurements.length(),1)',f'  assert_eq(r.measurements[0].offset_numerator,"{m["offset_numerator"]}")',f'  assert_eq(r.measurements[0].delay_numerator,"{m["mean_delay_numerator"]}")','  assert_eq(r.measurements[0].denominator,131072)']
 else:code += ['  assert_eq(r.measurements.length(),0)']
 code+=['}']
# JSON errors which cannot be expressed through the object fixture generator.
for name,text in [('duplicate keys','{"schema":"a","schema":"b"}'),('malformed JSON','['),('deep nesting','['*40+'0'+']'*40)]:
 code+=['///|',f'test "parser {name}" {{',f'  assert_eq(@audit.audit({json.dumps(text)}).exit_code(),1)','}']
# Protocol byte boundaries have direct field assertions as well as encode/decode equality.
wire_tests=['// Generated independent struct wire boundary vectors.']
for index,(correction,sec,ns,seq,interval) in enumerate([
 (-9223372036854775808,0,0,0,-128),(9223372036854775806,(1<<48)-1,999999999,65535,127),(-2,1,1,32768,-1),(1,0,999999999,1,0)]):
 raw=bytearray.fromhex(payload(8,seq=seq,correction=correction,sec=sec,ns=ns));raw[33]=interval&255
 # Convert decimal extrema into ordinary Int64 expressions acceptable to MoonBit.
 corr=('-9223372036854775807L - 1L') if correction==-9223372036854775808 else str(correction)+'L'
 wire_tests += ['///|',f'test "wire independent Int64 vector {index}" {{',f'  let bytes=match @wire.from_hex("{raw.hex()}") {{Ok(v)=>v;Err(_)=>panic()}}','  let p=match @wire.decode(bytes) {Ok(v)=>v;Err(_)=>panic()}',f'  assert_eq(p.header.correction,{corr})',f'  assert_eq(p.header.sequence,{seq})',f'  assert_eq(p.header.log_interval,{interval})',f'  assert_eq(p.header.source.clock,"{MASTER}")','  match p.body {',f'    @wire.TimestampBody(t)=>{{assert_eq(t.seconds,{sec}L);assert_eq(t.nanos,{ns})}}','    _=>assert_true(false)','  }',f'  assert_eq(@wire.to_hex(match @wire.encode(p) {{Ok(v)=>v;Err(_)=>panic()}}),"{raw.hex()}")','}']
(ROOT/'tests/wire_boundary_test.mbt').write_text('\n'.join(wire_tests)+'\n')
(ROOT/'tests/fixtures_test.mbt').write_text('\n'.join(code)+'\n')
print('Constructed fixtures:',len(rows),'measurement',measurement)
