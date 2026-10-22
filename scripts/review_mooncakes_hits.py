"""Attach explicit review dispositions to all automatic root-document hits."""
import json
from pathlib import Path
root=Path('research/2026-10-19');rows=json.load(open(root/'page-audit.json'));manual={r['name']:r for r in json.load(open(root/'reviewed-neighbors.json'))}
reason={
'Across2005/yimai_prophecy_moonbit':'用逻辑计数替换墙上时间保证应用可复现，不是物理时钟同步协议。',
'Ag108/MoonCache':'HTTP 缓存的注入 clock 与 Async 类型相邻触发宽泛正则。',
'daqing/moonkafka':'重试退避的 clock jitter / clients do not synchronize，不是时钟同步器或链路损伤模型。',
'dowdiness/incr':'增量计算的 revision 逻辑计数，不是 PTP 或物理时间同步。',
'helios-house/valence':'discrete_event 是离散状态变化的叙述 API，不能因词语相同认定仿真框架重复。',
'lampclaw/minimoon':'PageRuntime 与 Synchronize 应用状态相邻触发正则，非时钟同步。',
'mizchi/bit_io_native':'存储同步接口接收 Clock 参数，非时钟同步协议。',
'mizchi/bitx_hub':'Git/存储 SyncLink 与 Clock 参数相邻，非物理时钟同步。',
'mizchi/bitx_kv':'用于合并/冲突检测的逻辑时钟，非物理时钟同步。',
'mizchi/converge':'CRDT 的 Lamport 逻辑时钟，非物理时间同步。',
'mizchi/crdt_db':'CRDT 的 Lamport 逻辑时钟，非物理时间同步。',
'mizchi/wasmtime':'Wasm 运行时 FFI 的 clock_now_ns 与 async 配置邻接，非 PTP。',
'nexacodes/moontask':'任务运行时读取时钟，非时间同步协议或漂移控制。',
'qyt1234567/moonbit-modbus':'确定性 polling 的 logical-clock schedule，不是 PTP/BMCA。',
'RabitLogic/snowflake':'ID 生成器提示 NTP 回拨风险，属于同步结果的使用者，不提供同步协议。',
'riantr/snn_mbt':'network simulator 指神经元网络仿真，不是分组网络或时钟同步。',
'wallll-wal6/moonkv':'KV 数据库的 logical_clock 计数，不是 PTP/BMCA。',
'xuting22/rinex':'GNSS 文件校验项目的历史说明提及 NTP，不能据此判定包含 NTP/PTP 实现。',
}
out=[]
for r in rows:
 if not r.get('hits'):continue
 n=r['name']
 if n in manual:disposition=manual[n]['risk'];note=manual[n]['boundary']
 elif n.startswith('gaato/') or n in ['Lfan-ke/moonzero','moonbitstack/moonzero']:disposition='排除直接 PTP 命中';note='HTTP/SDK 的注入时钟和 async/同步类型邻接导致宽泛正则命中；不提供物理时钟同步。'
 elif n in ['Lfan-ke/moonraft','Lfan-ke/raft-moonbit','moonbitstack/moonraft']:disposition='排除直接 PTP 命中';note='Raft term 为逻辑时钟/任期，算法不是 IEEE 1588 BMCA。'
 elif n in reason:disposition='排除直接 PTP 命中';note=reason[n]
 else:raise ValueError('Unreviewed hit: '+n)
 out.append(dict(name=n,version=r['version'],url=r['url'],disposition=disposition,note=note,hits=r['hits']))
json.dump(out,open(root/'screening-review.json','w'),ensure_ascii=False,indent=2)
print('automatic-hit modules reviewed',len(out))
