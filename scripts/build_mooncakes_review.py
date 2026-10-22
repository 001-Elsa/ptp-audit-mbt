import json,re,hashlib
from pathlib import Path
root=Path('research/2026-10-19');mods={m['name']:m for m in json.load(open(root/'modules.json'))}
items=[
('xuting22/ntp','较高：物理时间同步功能部分相似','ClockFilter、Consensus、measure、Timestamp；提供偏移/延迟估计、过滤和时间源组合。','Timestamp、ClockQuality/select_grandmaster、Clock::apply_sync、simulate','NTP 与 PTP 的报文、源选择算法不同；当前 simulate 不是 NTP 的四时间戳测量实现。不能据协议不同排除功能相似。',r'ClockFilter|Consensus|measure|offset_seconds|delay_seconds'),
('Ljh684/moonnet-lab','较高：网络仿真能力部分重合','确定性分组网络仿真、虚拟时间、链路延迟、抖动、丢包及实验输出。','NetworkModel、SimulationConfig、SimulationReport、simulate','对方主要模拟 TCP 和队列，本地只有简化同步循环；共同的网络仿真功能仍然存在。',r'deterministic|jitter|loss|delay|virtual time'),
('oyjh0381/moonlab','中：确定性仿真和故障测试相似','分布式系统仿真、故障注入、确定性调度、重放和轨迹。','simulate、SimulationReport','对方是通用框架，本地是固定步进同步实验；不是完整相同实现。',r'deterministic|fault|Replay|Trace'),
('zlhahaha/moonsim','中：仿真和模型测试相似','确定性模型仿真、Sim/Rng/EventRecord、重放及网络/可靠性模型。','simulate、NetworkModel','本地没有对方的通用事件引擎和完整重放模型。',r'deterministic|replay|network|EventRecord'),
('wcx789ll/moonsim','中：分布式网络仿真相似','确定性离散事件及分布式网络仿真，虚拟时间、丢包、带宽队列、轨迹。','simulate、NetworkModel','本地不含通用离散事件引擎；网络条件和可复现实验存在交集。',r'deterministic|packet loss|virtual time|trace'),
('mokomoking2501/lockwire','中：虚拟时钟和仿真基础设施相似','确定性仿真/重放/故障注入，Instant、Duration、ClockRelation、VirtualClock、时钟域。','Timestamp、Clock、simulate','工业现场总线运行测试底座，不能据领域不同排除时钟与仿真功能交集。',r'ClockRelation|VirtualClock|Clock layer|replay|fault injection'),
('cauchyQ/moonbit-causalkit','邻近：时钟和事件仿真概念相似','HLC、版本向量、因果时间、延迟/离线消息仿真。','Timestamp、ClockEvent、simulate','逻辑/因果时钟与物理时钟同步解决的问题不同；不能据此认定同一 PTP 实现。',r'Hybrid Logical|causal time|delayed|simulator'),
('SCL-NN/moontracekit','邻近：逻辑时钟','Lamport/向量时钟、happens-before 和因果缓冲。','Timestamp、ClockEvent（仅概念层）','没有证据表明该包提供 IEEE 1588 或本地物理时间伺服。',r'Logical clocks|vector clocks|happens-before'),
('Asterless/MoonPtime','基础能力重合：时间表示和运算','POSIX 高精度时间、不可变时间表示、时间运算和格式化。','Timestamp、timestamp_parts、add/sub/abs','高精度时间基础能力已有包；不是 PTP 协议项目。',r'precision|representation|arithmetic|calculations'),
('SupremeHuaji/ptime','基础能力重合：时间表示和运算','皮秒精度时间、时间戳转换与时间运算。','Timestamp、timestamp_parts、add/sub','时间精度与接口不同，基础时间功能仍有交集。',r'Precision|nanoseconds|arithmetic|timestamp'),
('iceBear67/time','基础能力邻近：日期时间和时钟','日期时间、Instant、Duration、时钟以及 JS/Native 支持。','Timestamp','日期时间库与 PTP 同步协议不同。',r'clock|Instant|Duration'),
('walkzzz/moondes','邻近：离散事件仿真框架','事件队列、仿真时间、进程调度、资源和实验管理。','simulate（实验与时间推进层）','通用仿真基础设施，未发现 PTP 实现证据。',r'离散事件|EventQueue|仿真|time'),
('dxh8888/moonleasekit','邻近：选主与故障模拟概念','租约、fencing token、leader election、故障切换仿真。','select_grandmaster（只在选主这一抽象层）','租约/多数派选举与 BMCA 质量元组比较不同；不能认定 BMCA 重复。',r'leader election|select_candidate|failover'),
('lxyhgvb/moonbit-radioframe','邻近：网络链路仿真','无线帧、链路仿真、安全、路由及 6LoWPAN。','NetworkModel、simulate','无线协议领域不同；需避免把通用链路模拟宣传为生态空白。',r'jitter|loss|delay|simulation|仿真'),
('CYang-dep/moonosc','基础能力邻近：二进制时间标签','OSC 编解码、NTP era-zero timetag 与 Unix 时间转换；时钟同步由调用者提供。','Timestamp、encode/decode（时间及报文概念）','不是 NTP 时钟同步器，更不是 PTP 实现。',r'NTP|clock synchronization|timetag'),
('usagi-star/mooncap','邻近：网络报文处理','PCAP/PCAPNG 及常见网络协议离线解码。','encode/decode（仅二进制报文领域）','没有证据表明根文档列出的协议覆盖 PTP。',r'PCAP|Ethernet|UDP|TCP'),
('sbqrre/moonbit-mcu-hal','邻近：硬件时间与确定性模拟','timer/RTC、外设抽象、虚拟硬件和确定性内存后端。','Timestamp、simulate（通用基础概念）','不能等同于 IEEE 1588 硬件时间戳或 PTP 协议。',r'timer|RTC|deterministic|simulat'),
]
items += [
('mokomoking2501/MoonECAT','较高：工业分布式时钟功能相似','EtherCAT 主站，文档列出 Distributed Clock、SYNC0 配置、FRMW 漂移补偿、传播延迟和 DC jitter profiling。','Clock::apply_sync、NetworkModel、simulate（漂移、延迟和同步目标）','EtherCAT DC 与 IEEE 1588 协议不同；实际工业时间同步目标和部分功能相近，不能据协议差异排除。',r'Distributed Clock|SYNC0|drift compensation|propagation delay|DC jitter'),
('mokomoking2501/isoproject','邻近：同步保证的声明模型','ClockSyncGuarantee 枚举 NoSync/Causal/Windowed/Physical 以及链路能力模型。','Clock/NetworkModel（仅建模概念）','能力声明不是时钟同步算法，没有证据证明它实现 PTP。',r'ClockSyncGuarantee|clock-sync guarantee'),
('mokomoking2501/profinet_master','标准名命中：未证实 PTP 实现','工业 PROFINET 主站；snmp_feature_ieee_8021as_mib_optional API 和本地实时发送周期控制。','协议/时钟相关领域','802.1AS 可选 MIB 开关不等于 gPTP 协议实现；不能将该命中直接判作 PTP 重复。',r'ieee_8021as|clock highres|send_clock_factor'),
]
items += [
('hhxhhx78/moonbit-iec104','中：工业时钟同步命令功能相似','IEC 60870-5-104 带时标报文、ClockSyncTransaction、clock_sync_object 和时钟同步命令策略。','ClockEvent、时钟同步目标、时间戳和报文编解码','工业遥控的校时事务与 PTP 精密同步协议不同，但不能说工业对时功能在生态中不存在。',r'ClockSyncTransaction|clock_sync_object|时钟同步'),
('Lyllyl789/moon-kalman','邻近：传感器时间对齐与滤波','Kalman/EKF/UKF、传感器时间同步、异步传感器对时、Synchronizer 时间戳容差接受。','时间戳、同步/滤波建模概念','样本时间对齐和估计滤波不等于 PTP 物理时钟伺服，也不是本地 PI 算法重复证据。',r'Synchronizer|时间同步|异步传感器对时'),
('mjfmjf879/moonbit_constraint','邻近：确定性离散事件模型','整数事件时间、确定性事件排序、队列/服务/维护仿真和 CI 重放。','simulate（确定性建模基础概念）','约束求解/排队仿真领域不同，没有 PTP 实现证据。',r'discrete.event|simulation helpers|integer-based'),
('didiLjf/moonorbit','邻近：Actor 网络模拟','Actor 框架包含串行化、远程路由和 network simulator。','simulate、NetworkModel（网络模拟概念）','Actor 分发与 PTP 时钟协议不同；不据 network simulator 词语认定同一项目。',r'network simulator|Router|remote actor'),
('dgmlbtttt/iec104','邻近：工业协议和确定性仿真','索引和根文档描述 IEC104 协议栈与确定性变电站仿真，但根 README 仅指向项目说明。','协议编解码和 simulate（领域及基础概念）','根文档信息较少，不能推定完整内部功能已排除，也不能认定它实现 PTP。',r'deterministic substation|IEC 60870|README.md'),
]
out=[]
for name,risk,features,local,boundary,pattern in items:
 m=mods[name];p=root/'pages'/(name.replace('/','__')+'--'+hashlib.sha256((name+'@'+m['version']).encode()).hexdigest()[:12]+'.txt');s=p.read_text() if p.exists() else ''
 excerpts=[s[max(0,x.start()-100):x.end()+180] for x in list(re.finditer(pattern,s,re.I))[:6]]
 out.append(dict(name=name,version=m['version'],url='https://mooncakes.io/docs/'+name+'@'+m['version'],risk=risk,features=features,local=local,boundary=boundary,evidence_file=str(p),evidence_available=bool(s),excerpts=excerpts))
json.dump(out,open(root/'reviewed-neighbors.json','w'),ensure_ascii=False,indent=2)
print('review records',len(out),'missing evidence',[x['name'] for x in out if not x['evidence_available']])
