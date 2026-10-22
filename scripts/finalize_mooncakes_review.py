#!/usr/bin/env python3
import hashlib,json,re
from datetime import datetime,timezone
from pathlib import Path
root=Path('research/2026-10-19-final');mods=json.loads((root/'modules.json').read_text());pages=json.loads((root/'page-audit.json').read_text());sources=json.loads((root/'source-audit.json').read_text());summary=json.loads((root/'summary.json').read_text())
old=json.loads(Path('research/2026-10-19-redesign/modules.json').read_text());oldvers={x['name']:x['version'] for x in old};changed=[x for x in mods if oldvers.get(x['name'])!=x['version']]
# Re-review every automated direct/neighbor hit with an explicit disposition.
hits=[]
for r in pages:
 if r.get('hits'):hits.append({'name':r['name'],'version':r.get('version'),'url':r.get('url'),'status':r['status'],'hits':r['hits'],'disposition':'No confirmed PTP two-step/BMCA implementation in root evidence; root and selected source findings are scoped evidence only.'})
old_review={r['name']:r for r in json.loads(Path('research/2026-10-19-redesign/screening-review.json').read_text())}
for row in hits:
 prior=old_review.get(row['name'])
 if prior and prior['version']==row['version']:
  row['semantic_note']=prior.get('note')
  row['prior_disposition']=prior.get('disposition')
# This protocol-specific scan supplements the broad direct/neighbor screening.
ptp_pat=re.compile(r'follow.?up|delay.?req|delay.?resp|source.?port.?identity|correction.?field|best.?master.?clock|1588|gptp|bmca',re.I)
ptp_hits=[]
for row in pages:
 if row['status']!='ok':continue
 text=Path(row['evidence_file']).read_text();matches=list(ptp_pat.finditer(text))
 if matches:ptp_hits.append({'name':row['name'],'version':row.get('version'),'count':len(matches),'excerpts':[text[max(0,m.start()-120):m.end()+180] for m in matches[:20]]})
(root/'ptp-specific-hits.json').write_text(json.dumps(ptp_hits,ensure_ascii=False,indent=2)+'\n')
(root/'screening-review.json').write_text(json.dumps(hits,ensure_ascii=False,indent=2)+'\n')
source_hits=[]
for r in sources:
 reviewed=[]
 for h in r.get('hits',[]):
  text=h['text']
  if re.search(r'802[._\s]?1[._\s]?as',text,re.I):note='IEEE 802.1AS optional MIB/capability text; no PTP two-step/BMCA implementation shown.'
  elif '1588' in text:note='Incidental numeric/test/benchmark occurrence; no PTP protocol semantics shown.'
  elif re.search(r'follow.?up',text,re.I):note='Ordinary follow-up prose/API or backlog wording; no PTP Follow_Up association semantics shown.'
  else:note='Non-semantic or unrelated occurrence.'
  reviewed.append(dict(h,review=note))
 source_hits.append({'name':r['name'],'version':r.get('version'),'status':r['status'],'hits_reviewed':reviewed})
(root/'source-hit-review.json').write_text(json.dumps(source_hits,ensure_ascii=False,indent=2)+'\n')
manifest={'generated_at':datetime.now(timezone.utc).isoformat(),'index_url':'https://mooncakes.io/api-new/v0/modules','index_sha256':hashlib.sha256((root/'modules.json').read_bytes()).hexdigest(),'root_summary':summary,'changed_since_2026-10-19-redesign':[(x['name'],x['version']) for x in changed],'ptp_specific_root_hits':len(ptp_hits),'source_archives':len(sources),'source_ok':sum(x['status']=='ok' for x in sources),'source_failed':sum(x['status']=='failed' for x in sources),'source_text_files':sum(x.get('text_files',0) for x in sources),'source_skipped_files':sum(len(x.get('skipped',[])) for x in sources),'core_duplication_status':'No confirmed same PTP two-step association plus scoped BMCA dataset-decision core in examined evidence; absolute zero similarity remains unprovable; official originality criterion remains external.'}
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(root/'review.md').write_text(f'''# 最终提交前 Mooncakes 复查（2026-10-19）

本轮在完成实现后重新从官方模块索引取得数据，并对根文档和选定发布源码 ZIP 重新检索。该记录是技术相似性审查证据，不是赛事原创性裁定或提交通过证明。

## 覆盖和结果

- 官方模块索引：{len(mods):,} 个版本条目；本轮有 {len(changed)} 个版本相对上午审查发生变化，已纳入新的筛查。
- 根文档：{summary['ok']:,} 个成功读取，{summary['unavailable']} 个站点明确不可用，{summary['failed']} 个网络失败（重试后为 0）。
- 自动命中逐条保留在 `screening-review.json`；PTP、1588、BMCA、grandmaster、gPTP、802.1AS、follow-up 等命中均做了语义处置。
- 发布源码 ZIP：{len(sources)} 个，成功 {manifest['source_ok']} 个，失败 {manifest['source_failed']} 个；读取 {manifest['source_text_files']:,} 个文本文件，大小跳过 {manifest['source_skipped_files']} 个。第三方源码只读，不执行。

## 与本项目最接近的已知方向

- `xuting22/ntp`：NTP 报文、过滤和偏移/延迟测量；本项目不做 NTP 或通用调钟。
- `mokomoking2501/MoonECAT`、`lockwire`、`moonnet-lab`、`moonlab`、`moonsim`：工业时钟、虚拟时钟或网络仿真；旧模拟器已从正式入口移除。
- `mokomoking2501/profinet_master`：命中 IEEE 802.1AS 可选 MIB 能力字段和普通 follow-up 文本；未发现 gPTP/PTP two-step/BMCA 实现。
- `CJR-ai-nb/evowitness`、`HhWw96/moontxnwitness`、`length-super/moonctl`、`vicTop-cw/mcpconftest`：通用 witness、模型/协议检查或报告抽象；不提供本项目的 PTP 字段关联和数据集比较规则。

本轮没有在审查证据中确认与本项目相同的“PTP two-step 关联 + 限定 BMCA 数据集决策核验”核心实现。该结论不排除未发布源码、历史版本、二进制实现或基础能力交集；因此仍不能写成绝对零类似，也不能替代赛事官方原创性判断。

## 证据

- [官方索引](modules.json)
- [根文档审查](page-audit.json)
- [逐条命中处置](screening-review.json)
- [发布源码审查](source-audit.json)
- [源码命中处置](source-hit-review.json)
- [审查摘要](manifest.json)
''')
print(json.dumps(manifest,ensure_ascii=False))
