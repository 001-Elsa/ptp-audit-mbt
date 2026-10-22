#!/usr/bin/env python3
import hashlib,json,re
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parent.relative_to(Path.cwd())
mods=json.loads((ROOT/'modules.json').read_text());rows=json.loads((ROOT/'page-audit.json').read_text());sources=json.loads((ROOT/'source-audit.json').read_text());summary=json.loads((ROOT/'summary.json').read_text());delta=json.loads((ROOT/'index-delta.json').read_text())
old={r['name']:r for r in json.loads(Path('research/2026-10-19-final/screening-review.json').read_text())}
notes={
 'btlqql/moon_tracelens':'离线日志规范化、request_id分组、时间线与时间桶；与离线关联/时间窗口有通用功能交集，不含PTP sourcePortIdentity/sequence/correction/BMCA规则。followup命中是迭代文档/测试名。',
 'xuting22/rinex':'显式GPS daily/hourly窗口、时间间隔和缺失epoch检查；观察窗/缺失证据是基础设计交集，GNSS文件接收契约不等于PTP关联。',
 'z2823253773-p/moontick':'固定采样网格覆盖、缺失、重复和乱序时间戳审计；时间窗口与重复检查部分相似，不包含PTP报文和BMCA。',
 'mokomoking2501/concord':'协议AST、角色局部投影、trace-backed协议监控和违规报告；协议检查产品类别与迹线证据相似，当前AxisAuthority消息标签模型无PTP/BMCA规则。',
 'DDD12345-D/moon-snmp':'SNMP请求ID关联、重试/超时和stray-reply处理；关联与生命周期基础能力已有，未发现IEEE1588 two-step或BMCA。根页无README，以发布ZIP核实。',
 'Han-Wentao/mooniso8583':'ISO8583请求响应STAN/金额/终端/币种/DE90字段关联；具体协议字段不同，但字段关联检查这一通用能力部分相似。',
 'shangwuxi/moonradius':'RADIUS identifier/request-authenticator重传/冲突分类与有界请求缓存；重复键与生命周期管理基础能力有交集。',
 'Magic486/moonnetlink':'Netlink seq事务关联、DONE快照完成标记、loss/stale处理和重放；缺失不能当完整、快照有效前提等基础语义有交集，协议规则不同。',
 'yujieMamba/moonallen':'Allen定性区间约束、可核查见证与Unknown预算语义；时间和证据边界概念相似，不含精确PTP定点时间及报文关联。',
 'yyyt0807/moonbitemporal':'双时态事实、修订区间和历史决策证据；有效时序/决策复核抽象相似，不含PTP数据集比较。',
 'oyjh0381/moonipfix':'IPFIX模板驱动流记录解析、会话状态与结束时残余输入检查；网络报文审计及状态边界有交集，未发现PTP/BMCA规则。',
 'wcj12314/moon-flow-guard':'离线网络流/已解码包审计、Finding、门禁和跨流行为；产品类别存在部分功能相似。registry.mbt的1588是端口数字，35063(0x88F7)仅EtherType名称ptp，不是PTP消息实现。根页build失败，使用ZIP核实。',
 'chen-657/moon-change-window-auditor':'维护窗口冲突/冻结/依赖与安全时段规划；窗口校验属于通用交集，无协议交换或时钟数据集规则。',
 'LAOBIAO656/moonreplaykit':'确定性状态机重放、checkpoint和偏离诊断；重放/证据报告模式通用，不是PTP具体关联。',
 'zhangbowen2006/agentcanary':'AI工具历史离线策略回放、会话窗口费用/频率及审批过期；时间窗/过期/证据报告抽象相似，业务规则不同。',
 'mokomoking2501/profinet_master':'802.1AS命中为snmp_feature_ieee_8021as_mib_optional能力标志，源码为MIB声明/输出/测试，未发现gPTP报文关联或BMCA。',
 'any07557-wq/moonvcs':'新增VCS SHA256对象与惰性存储；offline/fetch_events词组命中，无PTP语义。',
 'cstoooo/mooniso_lite':'ISO20022 XML消息验证与支付状态对账；规则验证/关联报告是通用交集，无PTP核心。',
 'wiretokenbotca4491/wire_token':'新增HTTP RFC9110 token字符语法验证；wire名称不表示网络帧或PTP。',
 'golemcloud/golem_sdk_tools':'Golem Agent SDK代码生成工具；根页build失败，以70个发布文本核实，无PTP专项命中。',
 'riantr/moonbit_doubleML':'统计/因果机器学习估计器；follow-up为未来工作文字，未见PTP语义。',
 'agentdebug799/moonbit-triage':'医疗分诊观测新鲜度/排序API；时间前提是基础设计交集，无协议关联。',
 'bobzhang/differential':'差分数据流捕获/重放epoch及进度语义；观察分期/重复进度基础抽象有交集，未见PTP规则。',
 'mwqcodex/moonbitSPC':'统计过程控制的QualityWindow批次样本；观察窗名词不表示协议捕获窗口。',
 'Zxy666668/moonslokit':'SLO观测序列/窗口和预算；窗口与诊断通用，无PTP协议规则。',
 'vectie/moonbook':'业务证据观察窗和身份；可追溯性要求通用，无PTP协议规则。',
 'lsh775/moonbit_metrology':'计量检验的观测/容差/设备来源审查；离线可追溯规划类别邻近，非PTP。',
 'shop1111/frontierlab':'算法轨迹协议与离线HTML可视化；离线trace词语命中，非网络协议关联。',
}
review=[]
for row in rows:
 if not row.get('hits'):continue
 note=notes.get(row['name'])
 if note is None and row['name'] in old:note=old[row['name']].get('semantic_note') or old[row['name']].get('prior_disposition')
 if note is None:
  excerpts=' '.join(e for h in row['hits'] for e in h['excerpts'])
  if re.search(r'capture.{0,35}(Windows|window)|WINDOW_MOUSE_CAPTURE',excerpts,re.I):note='操作系统窗口/鼠标/屏幕捕获用语；不是协议观察窗口。'
  elif re.search(r'follow.?up|follow upstream',excerpts,re.I):note='后续工作、消息/任务跟进或普通follow-up API文本；未见PTP Follow_Up语义。'
  elif re.search(r'request.{0,25}correlat|requests.{0,20}correlat',excerpts,re.I):note='通用HTTP/JSONRPC请求关联标识；关联抽象有交集，所见摘录没有PTP报文规则。'
  else:note='领域特定观测/时间窗或普通offline/event文字；已读所存命中摘录，未定位PTP消息或BMCA语义。此为根页证据结论，不是全源码证明。'
 review.append(dict(name=row['name'],version=row['version'],evidence_file=row['evidence_file'],evidence_mode=row['evidence_mode'],hits=row['hits'],disposition=note))
change_review=[]
for change in delta['changes']:
 name=change['name'];row=next(r for r in rows if r['name']==name)
 if name in notes:note=notes[name]
 elif name.startswith('gmlewis/fonts'):note='字体轮廓/开放字体数据及编译器兼容更新；根文档无PTP/观察关联关键词命中，不把全部字体源码称已穷举。'
 elif name.startswith('gmlewis/'):note='压缩、哈希、I/O、图像或Wasm SDK基础库更新；共同字节/校验能力不独有，根文档未检出PTP核心。'
 elif name.startswith('golemcloud/'):note='持久Agent SDK/生成工具，根文档未定位PTP；tools另读源码ZIP。'
 else:note=change.get('description','')+'；本轮新根文档未定位PTP two-step/BMCA语义，常规解析/验证/回放抽象不视作独有。'
 change_review.append(dict(**change,evidence_file=row['evidence_file'],root_status=row['status'],review=note))
source_review=[]
for row in sources:
 hits=[]
 for hit in row.get('hits',[]):
  text=hit['text'];name=row['name']
  if name=='wcj12314/moon-flow-guard' and hit['path']=='registry.mbt':note='端口数值或EtherType 0x88F7名称查表；PTP标签本身不构成消息编解码/关联/BMCA实现。'
  elif name=='mokomoking2501/profinet_master' and re.search(r'802[._\s]?1[._\s]?as',text,re.I):note='PROFINET可选802.1AS MIB能力声明及测试。'
  elif re.search(r'1588',text) and not re.search(r'IEEE|PTP|1588-',text,re.I):note='数字/哈希/测试性能值中的1588子串，无协议语义。'
  elif re.search(r'follow.?up',text,re.I):note='迭代文档、测试函数或普通后续工作文字，无PTP Follow_Up语义。'
  else:note=notes.get(name,'网络/日志/策略领域的关联或观察邻近能力；所读命中未定位PTP/BMCA。')
  hits.append(dict(**hit,review=note))
 source_review.append(dict(name=row['name'],version=row.get('version'),evidence_mode=row['evidence_mode'],sha256=row.get('sha256'),review=notes.get(row['name'],'沿用已核实版本的历史源码审查，并以新关联/观察专项正则重新扫描；结论仍限于所读发布文本。'),hits_reviewed=hits))
manifest=dict(summary,completed_at=datetime.now(timezone.utc).isoformat(),index_url='https://mooncakes.io/api-new/v0/modules',baseline_manifest='research/2026-10-19-final/manifest.json',fresh_documents_are_delta_only=True,root_limitations=[dict(name=r['name'],version=r['version'],status=r['status'],evidence_file=r.get('evidence_file')) for r in rows if r['status']!='ok'],source_archives=len(sources),source_ok=sum(r['status']=='ok' for r in sources),source_failed=sum(r['status']!='ok' for r in sources),source_fresh=sum(r['evidence_mode']=='fresh_source_zip' for r in sources),source_reused=sum(r['evidence_mode']!='fresh_source_zip' for r in sources),source_text_files=sum(r.get('text_files',0) for r in sources),source_skipped_files=sum(len(r.get('skipped',[])) for r in sources),no_third_party_execution=True,no_publication_performed=True,conclusion='No confirmed same PTP two-step association plus scoped BMCA core in examined evidence. Generic packet correlation, capture/time windows, expiration, offline auditing and evidence reports overlap with existing projects. Absolute zero similarity is not established; organizer determination remains external.')
for name,data in [('screening-review.json',review),('changed-package-review.json',change_review),('source-hit-review.json',source_review),('manifest.json',manifest)]:ROOT.joinpath(name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(manifest,ensure_ascii=False))
