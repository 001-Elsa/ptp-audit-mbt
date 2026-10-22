# 实际实现规则逐项清单

本清单包含 95 个实际规则标识；逐个执行 169 个固定 CLI 案例，实际触发 73 个规则标识，并关联 219 个独立编译 LinuxPTP C 比较向量。清单内同时包含协议条件、项目范围和证据政策，不能把总规则数称为 IEEE 条款数。

生成命令：`python3 research/normative-completion/build_rule_inventory.py`。机器可读版本见 [rule-inventory.json](rule-inventory.json)。每条记录包含实际断言、源码行号、源码 SHA-256、公开官方依据、尚未证实的规范条件、实际触发 fixture 及独立 vector 名称。

每条公开来源依据均携带稳定 source_id、官方 URL、实际文档 SHA-256 和登记记录。新增 Garner 教程的第45页用于字段表示、第54/61页用于质量比较顺序、第62页用于逐分支 same-GM 方向旁证；教程仍标为非规范资料。完整 PDF 不随项目再分发，详见 [来源访问记录](source-access.md)。

这里的 fixture 覆盖是本次实际 CLI 的规则/状态覆盖，不是全部条件或分支覆盖；静态测试位置仅是定位，不能充当本次测试通过记录。完整后端测试结果仍以项目验收记录为准。

| 规则 | 当前实际检查 | 实际 CLI 规则触发 | 独立 C 向量 | 依据类别 |
|---|---|---:|---:|---|
| `BMCA.CANDIDATE_UNIQUENESS` | Candidate ids and referenced frame IDs are unique; duplicates are input violations. | 0 | 0 | project_input_or_evidence_policy |
| `BMCA.DIFFERENT_GM.clockAccuracy` | After equal prior fields, smaller unsigned clockAccuracy code wins. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.DIFFERENT_GM.clockClass` | After equal priority1, smaller clockClass wins. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.DIFFERENT_GM.identity` | After equal five quality fields, lexicographically smaller canonical GM identity wins (equivalent to unsigned octet ordering). | 2 | 2 | bounded_protocol_algorithm |
| `BMCA.DIFFERENT_GM.offsetScaledLogVariance` | After equal prior fields, smaller variance wins. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.DIFFERENT_GM.priority1` | For different GM identities, smaller priority1 wins at the first differing field. | 9 | 2 | bounded_protocol_algorithm |
| `BMCA.DIFFERENT_GM.priority2` | After equal prior fields, smaller priority2 wins. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.EVIDENCE` | Candidate snapshot is nonempty and caller explicitly confirms both completeness and eligibility. | 4 | 0 | project_input_or_evidence_policy |
| `BMCA.MISSING_FRAME` | Every BMCA candidate references an available, admissible Announce; partial candidate input cannot yield a preference verdict. | 1 | 0 | project_input_or_evidence_policy |
| `BMCA.OBSERVED_DECISION` | Observed selected candidate must match the conditional dataset winner; missing observed choice is InsufficientEvidence. | 21 | 0 | project_input_or_evidence_policy |
| `BMCA.RESOURCE` | At most 64 candidates; excess returns Unsupported. | 0 | 0 | project_scope_policy |
| `BMCA.SAME_GM.error1` | For a one-hop difference, equality of the longer path receiver and sender PortIdentity returns Unsupported. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.SAME_GM.error2` | Equal GM, steps, sender and receiver port leaves comparison unresolved and returns Unsupported. | 1 | 1 | bounded_protocol_algorithm |
| `BMCA.SAME_GM.oneHop` | For a one-hop difference, shorter path wins; topology flag is true precisely when longer.receiver > longer.sender in clock-identity/port order. | 2 | 4 | bounded_protocol_algorithm |
| `BMCA.SAME_GM.receiverPort` | For equal steps and sender identities, smaller receiver port number wins with topology flag. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.SAME_GM.sender` | For equal stepsRemoved and distinct sender identities, smaller sender PortIdentity wins with topology flag. | 2 | 4 | bounded_protocol_algorithm |
| `BMCA.SAME_GM.stepsRemoved` | For same GM and hop difference greater than one, fewer stepsRemoved wins without topology preference. | 1 | 2 | bounded_protocol_algorithm |
| `BMCA.SCOPE.CONTEXT` | Both compared candidates share domain and receiver clock identity. | 1 | 0 | project_scope_policy |
| `BMCA.SCOPE.DATASET` | Candidate id is nonempty; domain UInt8; canonical sender/receiver/GM identities; stepsRemoved 0..254; UInt8 priority/quality and UInt16 variance. | 1 | 0 | project_scope_policy |
| `BMCA.SCOPE.NO_UNIVERSAL_WINNER` | After successive comparisons, the proposed winner must beat every other candidate; unresolved/cyclic topology cannot produce a winner. | 0 | 0 | project_scope_policy |
| `BMCA.SNAPSHOT.EVIDENCE` | Explicit nonnegative epoch, nonblank window/domain, valid decision time, positive Announce validity and nonblank validity source. | 10 | 0 | project_input_or_evidence_policy |
| `BMCA.SNAPSHOT.EXPIRED` | Announce age decision_time-capture_time is nonnegative and at most declared validity; a future Announce is rejected here; excessive positive age may already fail the window-span rule. | 1 | 0 | project_input_or_evidence_policy |
| `BMCA.SNAPSHOT.FRESH` | Each candidate passed common context and nonnegative bounded age before dataset comparison; the validity source remains a caller assertion. | 29 | 0 | project_input_or_evidence_policy |
| `BMCA.SNAPSHOT.WINDOW` | Each Announce and decision share the common explicit observation-group predicate, complete capture window and validity budget. | 34 | 0 | project_input_or_evidence_policy |
| `CLAIM.AMBIGUOUS` | A Delay_Req or Delay_Resp reference must occur in exactly one exchange claim; repeated/conflicting claims cannot produce independent measurements. | 2 | 0 | project_input_or_evidence_policy |
| `CLAIM.DELAY_WINDOW` | Delay_Req/Delay_Resp subset satisfies the common observation-group predicate and Delay response budget. | 56 | 0 | project_input_or_evidence_policy |
| `CLAIM.E2E_IDENTITY` | Explicit quartet contains a valid Sync pair, Delay_Req and Delay_Resp, matching requester identity and request/response sequence, equal domain and epoch, and response source equals Sync source. | 44 | 0 | bounded_protocol_algorithm_with_evidence_preconditions |
| `CLAIM.EXCHANGE_WINDOW` | All four observations satisfy the common observation-group predicate using max(Sync budget, Delay budget). | 56 | 0 | project_input_or_evidence_policy |
| `CLAIM.MISSING_FRAME` | Every referenced frame in an explicit two/four-frame claim must be available and decodable before semantic comparison. | 1 | 0 | project_input_or_evidence_policy |
| `CLAIM.SYNC_FOLLOW_UP` | After valid common context, an explicitly asserted pair must satisfy supported kind, two-step, domain, source and sequence predicates; contradiction is a claim Violation. | 49 | 0 | bounded_protocol_algorithm_with_evidence_preconditions |
| `CLAIM.SYNC_WINDOW` | Explicit pair or four-frame Sync/Follow_Up subset satisfies the common observation-group predicate and Sync budget. | 59 | 0 | project_input_or_evidence_policy |
| `COMMISSION.BINDING.ACCEPTED` | Only a quartet with valid protocol arithmetic, identity, observation context and full selection/Announce interval coverage is conditionally accepted. | 27 | 0 | project_input_or_evidence_policy |
| `COMMISSION.BINDING.CONTEXT` | All quartet frames share the selected snapshot PTP domain, epoch, window and capture-clock context. | 1 | 0 | project_input_or_evidence_policy |
| `COMMISSION.BINDING.EVIDENCE` | Require at least one admitted four-frame measurement with all decoded frames and capture times; Announce-only evidence cannot establish that an exchange used the selected upstream. | 1 | 0 | project_input_or_evidence_policy |
| `COMMISSION.BINDING.IDENTITY` | Sync/Follow_Up/Delay_Resp source equals selected Announce sender; Delay_Req source and local receiver equal the selected candidate receiver. | 3 | 0 | project_input_or_evidence_policy |
| `COMMISSION.BINDING.VALIDITY` | Every quartet capture lies between the decision and both the confirmed stability deadline and selected Announce capture plus validity; no single-frame shortcut. | 2 | 0 | project_input_or_evidence_policy |
| `COMMISSION.CASE` | Retain exactly one raw audit report per campaign step and require all its admitted protocol/evidence checks to pass before binding an exchange to a selection. | 30 | 0 | project_input_or_evidence_policy |
| `COMMISSION.INPUT.RESOURCE` | At most 16 embedded steps and 1048576 UTF-16 units; CLI separately enforces a 1 MiB byte limit before parsing. | 1 | 0 | project_input_or_evidence_policy |
| `COMMISSION.INPUT.SCHEMA` | Strict ptp-commission/v1 campaign with unique nonblank step ids, bounded nesting, exact nested keys/scalar types, duplicate JSON key rejection and no partial acceptance on malformed input. | 3 | 0 | project_input_or_evidence_policy |
| `COMMISSION.SELECTION.EVIDENCE` | Require an explicit selected candidate from a passing valid BMCA snapshot; resolve candidate to Announce sender, receiver and grandmaster without guessing from a Delay_Req. | 1 | 0 | project_input_or_evidence_policy |
| `COMMISSION.STABILITY.EVIDENCE` | Require attributable confirmed stability of the selected upstream sender/grandmaster identities on the receiver/domain until a specified capture-clock deadline; a snapshot alone does not imply stability. | 2 | 0 | project_input_or_evidence_policy |
| `COMMISSION.STABILITY.WINDOW` | Decision and stability.until are ordered and covered by the selected snapshot observation window. | 1 | 0 | project_input_or_evidence_policy |
| `COMMISSION.TRANSITION.CONTRADICTORY_STABILITY` | Different selected sender/grandmaster identity pairs may not have overlapping confirmed stability intervals on the same receiver/domain and continuous capture clock. | 2 | 0 | project_input_or_evidence_policy |
| `COMMISSION.TRANSITION.EVIDENCE` | Only adjacent fully accepted steps with the same receiver/domain, an attributable confirmed continuous capture clock and strictly ordered quartet intervals can be compared; rejected middle steps are never bridged. | 17 | 0 | project_input_or_evidence_policy |
| `COMMISSION.TRANSITION.OBSERVED` | Report unchanged, sender-only, grandmaster-only or both changed using direct upstream and grandmaster separately; do not infer switch instant, failover duration, servo recovery or cross-master offset differences. | 9 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.DELAY_CONTEXT` | An unclaimed Delay_Req or Delay_Resp cannot establish a selected-master four-frame association. | 2 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.DELAY_DEADLINE` | Unassociated Delay_Req uses the caller-attributed Delay budget and valid observation window to distinguish pending/expired evidence. | 1 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.ORPHAN_FOLLOW_UP` | A Follow_Up without an observed matching Sync is InsufficientEvidence; capture completeness is not inferred. | 5 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.RESOURCE` | At most 256 frames, 256 explicit pair claims, and 256 exchange claims; excess returns Unsupported without partial arithmetic. | 0 | 0 | project_scope_policy |
| `EXCHANGE.STATE.CONTEXT` | Only observations satisfying explicit per-sample observation context and a positive applicable budget enter pending-state replay. | 9 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.STATE.EVICTED` | Timestamp-ordered pending state is physically removed when a later same-context event exceeds its deadline, or a confirmed complete window covers its deadline; expired state is never revived. | 20 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.STATE.PENDING` | An unmatched/ambiguous state is retained when capture coverage is incomplete or ends before its deadline. | 2 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.STATE.RESOURCE` | Lifecycle replay is bounded to 256 observations/claims. | 0 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.SYNC_DEADLINE` | Missing counterpart is classified using a caller-attributed positive Sync budget and capture window; complete coverage through deadline differs from early/incomplete capture, but neither proves device misconduct. | 10 | 0 | project_input_or_evidence_policy |
| `EXCHANGE.SYNC_FOLLOW_UP` | Automatic pairing requires Sync+Follow_Up, explicit equal epoch/window, equal domain/sourcePortIdentity/sequenceId, and Sync twoStepFlag. | 57 | 0 | bounded_protocol_algorithm_with_evidence_preconditions |
| `EXCHANGE.WINDOW` | An automatically found unique Sync/Follow_Up pair satisfies the common explicit observation-group predicate. | 55 | 0 | project_input_or_evidence_policy |
| `INPUT.FRAME_ID` | Typed input frame IDs are unique; JSON duplicates are rejected earlier as INPUT.SCHEMA. | 0 | 0 | project_input_or_evidence_policy |
| `INPUT.FRAME_METADATA` | Typed frame ID/epoch are nonnegative when present, event timestamp and local port are valid, and supplied direction is rx or tx. | 0 | 0 | project_input_or_evidence_policy |
| `INPUT.RESOURCE` | Typed JSON API accepts at most 1048576 UTF-16 code units; CLI independently limits regular-file bytes to 1 MiB. | 0 | 0 | project_input_or_evidence_policy |
| `INPUT.SCHEMA` | Strict root/nested keys, duplicate key rejection, maximum depth 32, bounded arrays, exact scalar types and decimal timestamp/budget ranges; malformed input yields no partial successful report. | 11 | 0 | project_input_or_evidence_policy |
| `MEASUREMENT.AMBIGUOUS` | Each of the four exchange message keys appears exactly once in the capture; sequence equality is not an ordering comparison and rollover is permitted. | 4 | 0 | project_input_or_evidence_policy |
| `MEASUREMENT.E2E` | F=(t2-t1)*65536-Sync.correction-Follow_Up.correction; R=(t4-t3)*65536-Delay_Resp.correction. | 28 | 0 | bounded_protocol_algorithm_with_evidence_preconditions |
| `MEASUREMENT.EVIDENCE` | t1 from Follow_Up, t4 from Delay_Resp, local t2 receive and t3 transmit event timestamps must exist. | 6 | 0 | project_input_or_evidence_policy |
| `MEASUREMENT.PATH_ASSUMPTIONS` | The inferred forward+reverse corrected duration cannot be negative under the supplied assumptions; contradiction returns InsufficientEvidence. | 1 | 0 | project_input_or_evidence_policy |
| `METROLOGY.ERROR_BUDGET` | Require an admitted quartet, four canonical nonnegative scaled-ns timestamp bounds, aggregate correction-error and full path-asymmetry bounds, limit, attributable source/assumptions and relative-rate confirmation; compute exact conditional interval. Limit verdict is separate from protocol validity. | 21 | 0 | project_input_or_evidence_policy |
| `METROLOGY.LEDGER` | Reconstruct each admitted PTP quartet timestamp/correction operand and every measurement integer; expose separate Sync, Follow_Up and Delay_Resp signed contributions while explicitly excluding Delay_Req correction. | 7 | 0 | project_input_or_evidence_policy |
| `OBSERVATION.POLICY` | Nonblank attributable policy source; every supplied association budget is a positive Int64. | 1 | 0 | project_input_or_evidence_policy |
| `OBSERVATION.RESOURCE` | At most 64 explicit observation windows. | 0 | 0 | project_input_or_evidence_policy |
| `OBSERVATION.WINDOW` | At least one window; unique printable nonblank id/domain, nonnegative epoch, valid start/end timestamps and start<=end. | 2 | 0 | project_input_or_evidence_policy |
| `SCOPE.CASE` | Input schema is ptp-audit/v1 and profile label default-e2e-two-step-2008; labels do not independently prove profile compliance. | 1 | 0 | project_scope_policy |
| `SCOPE.CORRECTION_TOO_BIG` | Either correctionField INT64_MAX or all-ones/-1 is unsupported because the two reviewed official interpretation responses describe conflicting tooBig encodings. | 2 | 0 | project_scope_policy |
| `SCOPE.FLAGS` | Flags intersecting mask 0xF8C0 are unsupported. This is a subset exclusion, not full message-specific flag applicability validation. | 0 | 0 | project_scope_policy |
| `SCOPE.MESSAGE` | messageType is 0, 1, 8, 9, or 11 (Sync, Delay_Req, Follow_Up, Delay_Resp, Announce). | 0 | 0 | project_scope_policy |
| `SCOPE.MODE` | Unicast/alternate-master bits intersecting 0x0500 are unsupported. | 0 | 0 | project_scope_policy |
| `SCOPE.NO_SEMANTIC_CHECK` | Decoding alone, without exchange inputs or a BMCA snapshot, does not produce a semantic Pass. | 14 | 0 | project_scope_policy |
| `SCOPE.PROFILE` | transportSpecific high nibble equals zero. This field alone does not establish default-profile qualification. | 0 | 0 | project_scope_policy |
| `SCOPE.TLV` | Declared payload longer than its fixed supported body is unsupported, without assuming the extra bytes are malformed TLVs. | 1 | 0 | project_scope_policy |
| `SCOPE.TWO_STEP` | Only Sync with twoStepFlag=1 is admitted to synchronization association. | 1 | 0 | project_scope_policy |
| `SCOPE.VERSION` | Entire version octet equals 0x02; later versions/minor-version use are outside the declared 2008 subset. | 0 | 0 | project_scope_policy |
| `WIRE.ANNOUNCE` | Typed Announce has valid timestamp, signed-16 UTC offset, UInt8 priorities/class/accuracy/timeSource, UInt16 variance/stepsRemoved, and canonical grandmaster clock identity. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.BODY_KIND` | Typed body variant matches header kind: timestamp for Sync/Delay_Req/Follow_Up, response for Delay_Resp, announcement for Announce. | 0 | 0 | project_input_or_evidence_policy |
| `WIRE.BODY_LENGTH` | Declared message is not shorter than the supported fixed body: 44 octets for Sync/Delay_Req/Follow_Up, 54 for Delay_Resp, 64 for Announce. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.CONTROL` | controlField is Sync=0, Delay_Req=1, Follow_Up=2, Delay_Resp=3, Announce=5. | 1 | 0 | bounded_protocol_encoding |
| `WIRE.FIELD_RANGE` | Typed encode requires canonical 8-octet source clock identity, port 1..65535, domain 0..255, sequence 0..65535, flags 0..65535, and log interval -128..127. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.FIXED_BODY` | A frame passed all implemented decoder checks. This summary is not every possible condition in Clause 13. | 111 | 0 | bounded_protocol_encoding |
| `WIRE.HEADER_LENGTH` | Payload contains at least the 34-octet common header before any indexed read. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.HEX` | Text has an even number of ASCII hexadecimal digits and at most 4096 characters; decoder accepts upper/lowercase, typed identities require canonical lowercase. | 1 | 0 | project_input_or_evidence_policy |
| `WIRE.MESSAGE_LENGTH` | messageLength equals the supplied PTP payload octet count. Transport padding must be removed before this API. | 1 | 0 | bounded_protocol_encoding |
| `WIRE.NANOSECONDS` | Decoded nanosecondsField is less than 1000000000; seconds use six unsigned big-endian octets. | 1 | 0 | bounded_protocol_encoding |
| `WIRE.REQUESTER_PORT` | Decoded Delay_Resp requestingPortIdentity portNumber is nonzero UInt16; actual device port count is unavailable. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.RESERVED` | Common-header offsets 5 and 16..19, plus Announce offset 46, are zero. | 1 | 0 | bounded_protocol_encoding |
| `WIRE.RESPONSE` | Typed Delay_Resp contains valid timestamp and canonical nonzero requester PortIdentity. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.SOURCE_PORT` | Decoded source portNumber is nonzero UInt16; actual defaultDS.numberPorts is unavailable. | 1 | 0 | bounded_protocol_encoding |
| `WIRE.TIMESTAMP` | Typed timestamp seconds are 0..281474976710655 and nanos 0..999999999. | 0 | 0 | bounded_protocol_encoding |
| `WIRE.TWO_STEP_FLAG` | twoStepFlag bit 0x0200 is zero for the four supported non-Sync message types; Sync two-step support is checked separately. | 4 | 0 | bounded_protocol_encoding |

## 重点审查结果

- **same-GM one-hop direction**：Shorter stepsRemoved wins. longer.receiver > longer.sender means topology=true. Both orderings and error1 equality appear in separately compiled LinuxPTP vectors. Independently rendered and visually reviewed Garner tutorial p62 corroborates all same-GM branches; it remains a non-normative official-hosted tutorial.
- **twoStepFlag applicability**：Official interpretation directly confirms Follow_Up=FALSE. The implementation also requires FALSE for Delay_Req/Delay_Resp/Announce; full Table20 applicability must be verified before promoting this to fully clause-reviewed.
- **control values**：0/1/2/3/5 and common offsets match independent fixtures/TShark and LinuxPTP layouts. Complete normative control enumeration remains to be reviewed.
- **correction sentinel**：INT64_MAX and -1 are excluded as Unsupported, not Violation. Public interpretation responses conflict; no unique sentinel resolution is asserted.
- **sequence and identity**：Associations use equality of domain/source/sequence and requester fields. No numeric sequence ordering crosses rollover. Epoch/window are supplied capture context; Delay_Req target master is an explicit claim.
- **field applicability completeness**：Remaining semantic enumerations, all message-specific flag/reserved-field conditions, sender initialization fields and logMessageInterval values are not exhaustively validated. WIRE.FIXED_BODY means only implemented checks passed.

## 不能用清单掩盖的限制

当前完整 IEEE/IEC 许可正文尚未纳入逐页复核。公开官方解释已经确认的内容，与仅有目录定位、LinuxPTP/TShark 实现旁证、以及项目自行规定的 epoch/window/timeout 政策在 JSON 中分开记录。填齐实现规则清单不等于完成未读正文的验证，也不等于全协议认证。

尚未由 CLI fixture 直接触发的规则也保留在清单中；其中 typed API 范围检查、资源上限和少数异常分支可能只在 MoonBit 测试中覆盖。不可从 CLI 汇总缺少某规则，反向推断它没有实现；同样不可把静态出现规则字符串算作执行通过。
