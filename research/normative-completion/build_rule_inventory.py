#!/usr/bin/env python3
"""Inventory implemented checks and collect actual CLI rule coverage.

This research tool does not certify IEEE compliance. It distinguishes protocol
checks, scope restrictions, input checks, and local evidence policy, records the
currently reviewed public sources, and names missing independent coverage.
"""
from collections import defaultdict
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
PATTERN = re.compile(r'"((?:WIRE|SCOPE|EXCHANGE|CLAIM|MEASUREMENT|BMCA|OBSERVATION|INPUT|METROLOGY|COMMISSION)\.[A-Za-z0-9_.]+)"')
SOURCES = [p for d in ('wire', 'exchange', 'bmca', 'observation', 'audit', 'metrology', 'commissioning')
           for p in sorted((ROOT / d).glob('*.mbt')) if 'test' not in p.name]

# These are observed document hashes, not hashes of a complete licensed IEEE
# standard. Each per-rule fact retains both the locator and the source tier.
SOURCE_REGISTER = {
 'ieee1588-interpretations-2011': {
  'title': 'IEEE 1588-2008 official interpretations',
  'url': 'https://standards.ieee.org/wp-content/uploads/import/documents/interpretations/1588-2008_interp.pdf',
  'sha256': 'fae8481cbaad0657d6e094a789cbf15afe57850991271d90fb9cdddc3fdb3bb5',
  'source_type': 'official_publisher_interpretation_responses',
  'complete_normative_standard': False,
  'registration_record': 'research/wire-reference/sources/README.md',
  'licence_boundary': 'Full interpretation document is not redistributed; short reviewed facts and source hashes only.',
 },
 'iec61588-2009-official-preview': {
  'title': 'IEC 61588:2009 official preview',
  'url': 'https://webstore.iec.ch/en/iec_catalog/product/preview/?id=L3B1Yi9wZGYvcHJldmlldy9pbmZvX2llYzYxNTg4e2VkMi4wfWVuLnBkZg==',
  'sha256': 'e33a07902fcd4ea7812dc09cdb9be66f3cc72c71f38990fe531ea1a8c08ca439',
  'source_type': 'official_publisher_preview',
  'complete_normative_standard': False,
  'registration_record': 'research/wire-reference/sources/README.md',
  'source_access_record': 'research/normative-completion/source-access.json',
  'licence_boundary': 'Nineteen-page preview, not the 287-page licensed edition; full document is not bundled.',
 },
 'ieee802-cummings-header-contribution-2015': {
  'title': 'IEEE 802.1 public contribution as-cummings-1588-upkeep-work-item-89-0315-v1',
  'url': 'https://www.ieee802.org/1/files/public/docs2015/as-cummings-1588-upkeep-work-item-89-0315-v1.pdf',
  'sha256': '862d9ea35675a982bf473ebfe0e3aa728286ffdd8cd32325acdcd9a2a14458db',
  'source_type': 'non_normative_official_hosted_working_group_contribution',
  'complete_normative_standard': False,
  'registration_record': 'research/wire-reference/sources/README.md',
  'licence_boundary': 'Publicly hosted contribution; hosting does not turn it into a standard or grant full-document redistribution.',
 },
 'ieee802-garner-1588v2-tutorial-2008': {
  'title': 'IEEE 802.1 publicly hosted Geoffrey M. Garner IEEE 1588 Version 2 tutorial, September 24, 2008',
  'url': 'https://www.ieee802.org/1/files/public/docs2008/as-garner-1588v2-summary-0908.pdf',
  'sha256': 'a023d1d55e20fe4b3ea5dbf11cdcfd650abfa071c3cab11e8247de6ff4eece68',
  'source_type': 'non_normative_official_hosted_tutorial',
  'complete_normative_standard': False,
  'registration_record': 'research/normative-completion/source-access.md',
  'source_access_record': 'research/normative-completion/source-access.json',
  'licence_boundary': 'Complete 89-page research copy is retained outside the repository; only reviewed facts, provenance and hashes are bundled. Public availability is not a redistribution licence.',
 },
}
SOURCE_BY_TITLE = {entry['title']: source_id for source_id, entry in SOURCE_REGISTER.items()}
GARNER = 'ieee802-garner-1588v2-tutorial-2008'

# Each entry describes the implemented predicate, not a paraphrased IEEE shall.
CONDITIONS = {
 'COMMISSION.CASE': ['Retain exactly one raw audit report per campaign step and require all its admitted protocol/evidence checks to pass before binding an exchange to a selection.'],
 'COMMISSION.INPUT.SCHEMA': ['Strict ptp-commission/v1 campaign with unique nonblank step ids, bounded nesting, exact nested keys/scalar types, duplicate JSON key rejection and no partial acceptance on malformed input.'],
 'COMMISSION.INPUT.RESOURCE': ['At most 16 embedded steps and 1048576 UTF-16 units; CLI separately enforces a 1 MiB byte limit before parsing.'],
 'COMMISSION.SELECTION.EVIDENCE': ['Require an explicit selected candidate from a passing valid BMCA snapshot; resolve candidate to Announce sender, receiver and grandmaster without guessing from a Delay_Req.'],
 'COMMISSION.STABILITY.EVIDENCE': ['Require attributable confirmed stability of the selected upstream sender/grandmaster identities on the receiver/domain until a specified capture-clock deadline; a snapshot alone does not imply stability.'],
 'COMMISSION.STABILITY.WINDOW': ['Decision and stability.until are ordered and covered by the selected snapshot observation window.'],
 'COMMISSION.BINDING.EVIDENCE': ['Require at least one admitted four-frame measurement with all decoded frames and capture times; Announce-only evidence cannot establish that an exchange used the selected upstream.'],
 'COMMISSION.BINDING.IDENTITY': ['Sync/Follow_Up/Delay_Resp source equals selected Announce sender; Delay_Req source and local receiver equal the selected candidate receiver.'],
 'COMMISSION.BINDING.CONTEXT': ['All quartet frames share the selected snapshot PTP domain, epoch, window and capture-clock context.'],
 'COMMISSION.BINDING.VALIDITY': ['Every quartet capture lies between the decision and both the confirmed stability deadline and selected Announce capture plus validity; no single-frame shortcut.'],
 'COMMISSION.BINDING.ACCEPTED': ['Only a quartet with valid protocol arithmetic, identity, observation context and full selection/Announce interval coverage is conditionally accepted.'],
 'COMMISSION.TRANSITION.EVIDENCE': ['Only adjacent fully accepted steps with the same receiver/domain, an attributable confirmed continuous capture clock and strictly ordered quartet intervals can be compared; rejected middle steps are never bridged.'],
 'COMMISSION.TRANSITION.CONTRADICTORY_STABILITY': ['Different selected sender/grandmaster identity pairs may not have overlapping confirmed stability intervals on the same receiver/domain and continuous capture clock.'],
 'COMMISSION.TRANSITION.OBSERVED': ['Report unchanged, sender-only, grandmaster-only or both changed using direct upstream and grandmaster separately; do not infer switch instant, failover duration, servo recovery or cross-master offset differences.'],
 'METROLOGY.LEDGER': ['Reconstruct each admitted PTP quartet timestamp/correction operand and every measurement integer; expose separate Sync, Follow_Up and Delay_Resp signed contributions while explicitly excluding Delay_Req correction.'],
 'METROLOGY.ERROR_BUDGET': ['Require an admitted quartet, four canonical nonnegative scaled-ns timestamp bounds, aggregate correction-error and full path-asymmetry bounds, limit, attributable source/assumptions and relative-rate confirmation; compute exact conditional interval. Limit verdict is separate from protocol validity.'],
 'WIRE.HEX': ['Text has an even number of ASCII hexadecimal digits and at most 4096 characters; decoder accepts upper/lowercase, typed identities require canonical lowercase.'],
 'WIRE.NANOSECONDS': ['Decoded nanosecondsField is less than 1000000000; seconds use six unsigned big-endian octets.'],
 'WIRE.HEADER_LENGTH': ['Payload contains at least the 34-octet common header before any indexed read.'],
 'SCOPE.VERSION': ['Entire version octet equals 0x02; later versions/minor-version use are outside the declared 2008 subset.'],
 'SCOPE.PROFILE': ['transportSpecific high nibble equals zero. This field alone does not establish default-profile qualification.'],
 'SCOPE.MESSAGE': ['messageType is 0, 1, 8, 9, or 11 (Sync, Delay_Req, Follow_Up, Delay_Resp, Announce).'],
 'WIRE.MESSAGE_LENGTH': ['messageLength equals the supplied PTP payload octet count. Transport padding must be removed before this API.'],
 'WIRE.BODY_LENGTH': ['Declared message is not shorter than the supported fixed body: 44 octets for Sync/Delay_Req/Follow_Up, 54 for Delay_Resp, 64 for Announce.'],
 'SCOPE.TLV': ['Declared payload longer than its fixed supported body is unsupported, without assuming the extra bytes are malformed TLVs.'],
 'WIRE.RESERVED': ['Common-header offsets 5 and 16..19, plus Announce offset 46, are zero.', 'This audits sender-side reserved-field encoding; receivers are not asserted to be required to reject nonzero values.'],
 'WIRE.CONTROL': ['controlField is Sync=0, Delay_Req=1, Follow_Up=2, Delay_Resp=3, Announce=5.'],
 'WIRE.TWO_STEP_FLAG': ['twoStepFlag bit 0x0200 is zero for the four supported non-Sync message types; Sync two-step support is checked separately.'],
 'SCOPE.CORRECTION_TOO_BIG': ['Either correctionField INT64_MAX or all-ones/-1 is unsupported because the two reviewed official interpretation responses describe conflicting tooBig encodings.', 'Other signed correction values are preserved exactly at 2^-16 ns resolution; excluding -1 is conservative local scope, not a claim that every -1 is invalid.'],
 'SCOPE.FLAGS': ['Flags intersecting mask 0xF8C0 are unsupported. This is a subset exclusion, not full message-specific flag applicability validation.'],
 'SCOPE.MODE': ['Unicast/alternate-master bits intersecting 0x0500 are unsupported.'],
 'WIRE.SOURCE_PORT': ['Decoded source portNumber is nonzero UInt16; actual defaultDS.numberPorts is unavailable.'],
 'WIRE.REQUESTER_PORT': ['Decoded Delay_Resp requestingPortIdentity portNumber is nonzero UInt16; actual device port count is unavailable.'],
 'WIRE.FIELD_RANGE': ['Typed encode requires canonical 8-octet source clock identity, port 1..65535, domain 0..255, sequence 0..65535, flags 0..65535, and log interval -128..127.'],
 'WIRE.TIMESTAMP': ['Typed timestamp seconds are 0..281474976710655 and nanos 0..999999999.'],
 'WIRE.RESPONSE': ['Typed Delay_Resp contains valid timestamp and canonical nonzero requester PortIdentity.'],
 'WIRE.ANNOUNCE': ['Typed Announce has valid timestamp, signed-16 UTC offset, UInt8 priorities/class/accuracy/timeSource, UInt16 variance/stepsRemoved, and canonical grandmaster clock identity.', 'The bounds check does not validate every semantic/reserved enumeration of clockClass, clockAccuracy, timeSource, or flag-dependent UTC properties.'],
 'WIRE.BODY_KIND': ['Typed body variant matches header kind: timestamp for Sync/Delay_Req/Follow_Up, response for Delay_Resp, announcement for Announce.'],
 'WIRE.FIXED_BODY': ['A frame passed all implemented decoder checks. This summary is not every possible condition in Clause 13.'],
 'EXCHANGE.RESOURCE': ['At most 256 frames, 256 explicit pair claims, and 256 exchange claims; excess returns Unsupported without partial arithmetic.'],
 'INPUT.FRAME_ID': ['Typed input frame IDs are unique; JSON duplicates are rejected earlier as INPUT.SCHEMA.'],
 'INPUT.FRAME_METADATA': ['Typed frame ID/epoch are nonnegative when present, event timestamp and local port are valid, and supplied direction is rx or tx.'],
 'SCOPE.TWO_STEP': ['Only Sync with twoStepFlag=1 is admitted to synchronization association.'],
 'EXCHANGE.WINDOW': ['An automatically found unique Sync/Follow_Up pair satisfies the common explicit observation-group predicate.'],
 'EXCHANGE.SYNC_FOLLOW_UP': ['Automatic pairing requires Sync+Follow_Up, explicit equal epoch/window, equal domain/sourcePortIdentity/sequenceId, and Sync twoStepFlag.', 'Exactly one matching Follow_Up and one Sync of that key are observed; duplicates/missing data yield InsufficientEvidence rather than device violation.'],
 'EXCHANGE.SYNC_DEADLINE': ['Missing counterpart is classified using a caller-attributed positive Sync budget and capture window; complete coverage through deadline differs from early/incomplete capture, but neither proves device misconduct.'],
 'EXCHANGE.ORPHAN_FOLLOW_UP': ['A Follow_Up without an observed matching Sync is InsufficientEvidence; capture completeness is not inferred.'],
 'CLAIM.SYNC_WINDOW': ['Explicit pair or four-frame Sync/Follow_Up subset satisfies the common observation-group predicate and Sync budget.'],
 'CLAIM.SYNC_FOLLOW_UP': ['After valid common context, an explicitly asserted pair must satisfy supported kind, two-step, domain, source and sequence predicates; contradiction is a claim Violation.'],
 'CLAIM.MISSING_FRAME': ['Every referenced frame in an explicit two/four-frame claim must be available and decodable before semantic comparison.'],
 'CLAIM.AMBIGUOUS': ['A Delay_Req or Delay_Resp reference must occur in exactly one exchange claim; repeated/conflicting claims cannot produce independent measurements.'],
 'CLAIM.DELAY_WINDOW': ['Delay_Req/Delay_Resp subset satisfies the common observation-group predicate and Delay response budget.'],
 'CLAIM.EXCHANGE_WINDOW': ['All four observations satisfy the common observation-group predicate using max(Sync budget, Delay budget).'],
 'CLAIM.E2E_IDENTITY': ['Explicit quartet contains a valid Sync pair, Delay_Req and Delay_Resp, matching requester identity and request/response sequence, equal domain and epoch, and response source equals Sync source.', 'Delay_Req does not encode its intended master; that association is explicitly supplied, not discovered from the request alone.'],
 'MEASUREMENT.AMBIGUOUS': ['Each of the four exchange message keys appears exactly once in the capture; sequence equality is not an ordering comparison and rollover is permitted.'],
 'MEASUREMENT.EVIDENCE': ['t1 from Follow_Up, t4 from Delay_Resp, local t2 receive and t3 transmit event timestamps must exist.', 'Sync local receive and Delay_Req local transmit share the requester PortIdentity and a nonblank event clock domain.', 'Caller confirms symmetric path, timestamp provenance and stable relative clock rates.'],
 'MEASUREMENT.PATH_ASSUMPTIONS': ['The inferred forward+reverse corrected duration cannot be negative under the supplied assumptions; contradiction returns InsufficientEvidence.'],
 'MEASUREMENT.E2E': ['F=(t2-t1)*65536-Sync.correction-Follow_Up.correction; R=(t4-t3)*65536-Delay_Resp.correction.', 'Offset=(F-R)/131072 ns; mean delay=(F+R)/131072 ns, using exact arbitrary precision integers; Delay_Req correction is not subtracted twice.'],
 'EXCHANGE.DELAY_DEADLINE': ['Unassociated Delay_Req uses the caller-attributed Delay budget and valid observation window to distinguish pending/expired evidence.'],
 'EXCHANGE.DELAY_CONTEXT': ['An unclaimed Delay_Req or Delay_Resp cannot establish a selected-master four-frame association.'],
 'EXCHANGE.STATE.EVICTED': ['Timestamp-ordered pending state is physically removed when a later same-context event exceeds its deadline, or a confirmed complete window covers its deadline; expired state is never revived.'],
 'EXCHANGE.STATE.PENDING': ['An unmatched/ambiguous state is retained when capture coverage is incomplete or ends before its deadline.'],
 'EXCHANGE.STATE.RESOURCE': ['Lifecycle replay is bounded to 256 observations/claims.'],
 'EXCHANGE.STATE.CONTEXT': ['Only observations satisfying explicit per-sample observation context and a positive applicable budget enter pending-state replay.'],
 'BMCA.SCOPE.DATASET': ['Candidate id is nonempty; domain UInt8; canonical sender/receiver/GM identities; stepsRemoved 0..254; UInt8 priority/quality and UInt16 variance.', 'Dataset comparison does not implement foreign-master qualification, local-master election or port-state decisions.'],
 'BMCA.SCOPE.CONTEXT': ['Both compared candidates share domain and receiver clock identity.'],
 'BMCA.DIFFERENT_GM.priority1': ['For different GM identities, smaller priority1 wins at the first differing field.'],
 'BMCA.DIFFERENT_GM.clockClass': ['After equal priority1, smaller clockClass wins.'],
 'BMCA.DIFFERENT_GM.clockAccuracy': ['After equal prior fields, smaller unsigned clockAccuracy code wins.'],
 'BMCA.DIFFERENT_GM.offsetScaledLogVariance': ['After equal prior fields, smaller variance wins.'],
 'BMCA.DIFFERENT_GM.priority2': ['After equal prior fields, smaller priority2 wins.'],
 'BMCA.DIFFERENT_GM.identity': ['After equal five quality fields, lexicographically smaller canonical GM identity wins (equivalent to unsigned octet ordering).'],
 'BMCA.SAME_GM.stepsRemoved': ['For same GM and hop difference greater than one, fewer stepsRemoved wins without topology preference.'],
 'BMCA.SAME_GM.error1': ['For a one-hop difference, equality of the longer path receiver and sender PortIdentity returns Unsupported.'],
 'BMCA.SAME_GM.oneHop': ['For a one-hop difference, shorter path wins; topology flag is true precisely when longer.receiver > longer.sender in clock-identity/port order.'],
 'BMCA.SAME_GM.sender': ['For equal stepsRemoved and distinct sender identities, smaller sender PortIdentity wins with topology flag.'],
 'BMCA.SAME_GM.receiverPort': ['For equal steps and sender identities, smaller receiver port number wins with topology flag.'],
 'BMCA.SAME_GM.error2': ['Equal GM, steps, sender and receiver port leaves comparison unresolved and returns Unsupported.'],
 'BMCA.EVIDENCE': ['Candidate snapshot is nonempty and caller explicitly confirms both completeness and eligibility.'],
 'BMCA.RESOURCE': ['At most 64 candidates; excess returns Unsupported.'],
 'BMCA.CANDIDATE_UNIQUENESS': ['Candidate ids and referenced frame IDs are unique; duplicates are input violations.'],
 'BMCA.SCOPE.NO_UNIVERSAL_WINNER': ['After successive comparisons, the proposed winner must beat every other candidate; unresolved/cyclic topology cannot produce a winner.'],
 'BMCA.OBSERVED_DECISION': ['Observed selected candidate must match the conditional dataset winner; missing observed choice is InsufficientEvidence.', 'This is not a complete Clause 9 port-state or device behavior certification.'],
 'BMCA.SNAPSHOT.EVIDENCE': ['Explicit nonnegative epoch, nonblank window/domain, valid decision time, positive Announce validity and nonblank validity source.', 'Caller confirms validity and capture coverage; exactly one capture metadata record exists per candidate.'],
 'BMCA.SNAPSHOT.WINDOW': ['Each Announce and decision share the common explicit observation-group predicate, complete capture window and validity budget.'],
 'BMCA.SNAPSHOT.EXPIRED': ['Announce age decision_time-capture_time is nonnegative and at most declared validity; a future Announce is rejected here; excessive positive age may already fail the window-span rule.'],
 'BMCA.SNAPSHOT.FRESH': ['Each candidate passed common context and nonnegative bounded age before dataset comparison; the validity source remains a caller assertion.'],
 'OBSERVATION.RESOURCE': ['At most 64 explicit observation windows.'],
 'OBSERVATION.WINDOW': ['At least one window; unique printable nonblank id/domain, nonnegative epoch, valid start/end timestamps and start<=end.'],
 'OBSERVATION.POLICY': ['Nonblank attributable policy source; every supplied association budget is a positive Int64.'],
 'SCOPE.CASE': ['Input schema is ptp-audit/v1 and profile label default-e2e-two-step-2008; labels do not independently prove profile compliance.'],
 'BMCA.MISSING_FRAME': ['Every BMCA candidate references an available, admissible Announce; partial candidate input cannot yield a preference verdict.'],
 'SCOPE.NO_SEMANTIC_CHECK': ['Decoding alone, without exchange inputs or a BMCA snapshot, does not produce a semantic Pass.'],
 'INPUT.RESOURCE': ['Typed JSON API accepts at most 1048576 UTF-16 code units; CLI independently limits regular-file bytes to 1 MiB.'],
 'INPUT.SCHEMA': ['Strict root/nested keys, duplicate key rejection, maximum depth 32, bounded arrays, exact scalar types and decimal timestamp/budget ranges; malformed input yields no partial successful report.'],
}
GROUP_PREDICATE = [
 'Every sample has nonnegative frame ID and explicit nonnegative epoch, valid capture timestamp, printable nonblank clock domain and unambiguous window reference.',
 'Each sample matches its window epoch/clock and lies within its start/end; the group shares epoch/window/capture clock.',
 'Required complete coverage is explicitly confirmed; a positive applicable budget exists; capture max-min does not exceed budget.',
 'No timeout or freshness budget is inferred from a universal IEEE timeout or from logMessageInterval.',
]

def raw_basis(rule):
    if rule.startswith(('INPUT.', 'OBSERVATION.', 'EXCHANGE.STATE.', 'BMCA.SNAPSHOT.', 'METROLOGY.', 'COMMISSION.')):
        return {'classification': 'project_input_or_evidence_policy', 'official': [], 'unverified': []}
    if rule.startswith('SCOPE.') or rule in ('EXCHANGE.RESOURCE', 'BMCA.RESOURCE', 'BMCA.SCOPE.DATASET', 'BMCA.SCOPE.CONTEXT', 'BMCA.SCOPE.NO_UNIVERSAL_WINNER'):
        facts = []
        if rule == 'SCOPE.CORRECTION_TOO_BIG':
            facts = [{'source': 'IEEE 1588-2008 official interpretations', 'locator': '#25 p21 and #27 pp23-24', 'level': 'reviewed_official_response', 'fact': 'Two responses describe conflicting tooBig sentinels; signed scaled correction is supported.'}]
        return {'classification': 'project_scope_policy', 'official': facts, 'unverified': []}
    if rule.startswith('BMCA.DIFFERENT_GM.'):
        return {'classification': 'bounded_protocol_algorithm', 'official': [{'source': 'IEEE 1588-2008 official interpretations', 'locator': '#31 p28; 9.3.4 / Figure 27', 'level': 'reviewed_official_response', 'fact': 'Priority precedence: priority1, class, accuracy, variance, priority2, GM identity.'}], 'unverified': ['Full eligibility, all quality code semantics and full state decisions are not part of this comparison.']}
    if rule.startswith('BMCA.SAME_GM.'):
        return {'classification': 'bounded_protocol_algorithm', 'official': [{'source': 'IEC 61588:2009 official preview', 'locator': 'Contents; 9.3.4 / Figures 27-28', 'level': 'locator_only', 'fact': 'Locates dataset comparison; no full same-GM branch text was available in the reviewed preview.'}], 'unverified': ['Same-GM branches have independent LinuxPTP implementation coverage, but were not independently read from full licensed normative pages.']}
    if rule in ('WIRE.HEX', 'WIRE.BODY_KIND', 'INPUT.FRAME_ID', 'INPUT.FRAME_METADATA', 'BMCA.CANDIDATE_UNIQUENESS'):
        return {'classification': 'project_input_or_evidence_policy', 'official': [], 'unverified': []}
    if rule.startswith('WIRE.'):
        official = [{'source': 'IEC 61588:2009 official preview', 'locator': 'Clause 13 / Tables 18,25-28', 'level': 'locator_only', 'fact': 'Locates common header and the five supported message formats; contents alone do not prove field constraints.'}]
        gaps = ['Full normative body lengths, value constraints and message-specific field applicability still require verified normative text.']
        if rule in ('WIRE.HEADER_LENGTH', 'WIRE.MESSAGE_LENGTH', 'WIRE.RESERVED', 'WIRE.CONTROL', 'WIRE.FIXED_BODY'):
            official.append({'source': 'IEEE 802.1 public contribution as-cummings-1588-upkeep-work-item-89-0315-v1', 'locator': 'pp2,4; reproduced Table 18', 'level': 'non_normative_official_hosted_contribution', 'fact': 'Common-header offsets and reserved transmit-zero/receive-ignore behavior.'})
        if rule == 'WIRE.TWO_STEP_FLAG':
            official.append({'source': 'IEEE 1588-2008 official interpretations', 'locator': '#11 p7; Table 20 discussion', 'level': 'reviewed_official_response', 'fact': 'Follow_Up twoStepFlag FALSE; two-step Sync signals a following Follow_Up.'})
            gaps = ['Reviewed interpretation explicitly covers Follow_Up; full Table 20 applicability for other supported non-Sync types requires direct verification.']
        if rule in ('WIRE.SOURCE_PORT', 'WIRE.REQUESTER_PORT'):
            official.append({'source': 'IEEE 1588-2008 official interpretations', 'locator': '#21 pp14-15 / 7.5.2.3', 'level': 'reviewed_official_response', 'fact': 'portNumber is 1..N, N=defaultDS.numberPorts.'})
            gaps = ['No numberPorts dataset is supplied; nonzero UInt16 only proves representation, not an actually existing device port.']
        return {'classification': 'bounded_protocol_encoding', 'official': official, 'unverified': gaps}
    if rule in ('CLAIM.SYNC_FOLLOW_UP', 'EXCHANGE.SYNC_FOLLOW_UP', 'CLAIM.E2E_IDENTITY', 'MEASUREMENT.E2E'):
        official = []
        if rule != 'CLAIM.E2E_IDENTITY':
            official.append({'source': 'IEEE 1588-2008 official interpretations', 'locator': '#11 p7' if 'FOLLOW_UP' in rule else '#25 p21 / #27 pp23-24', 'level': 'reviewed_official_response', 'fact': 'Two-step Follow_Up behavior' if 'FOLLOW_UP' in rule else 'Signed scaled correction representation; conflicting sentinel responses.'})
        return {'classification': 'bounded_protocol_algorithm_with_evidence_preconditions', 'official': official, 'unverified': ['Full Clause 11 matching/arithmetic behavior and complete Clause 13 fields have not been reviewed in licensed full text; capture epoch/window and assumptions are local policy.']}
    return {'classification': 'project_input_or_evidence_policy', 'official': [], 'unverified': []}

def tutorial_fact(locator, fact):
    return {'source': SOURCE_REGISTER[GARNER]['title'], 'locator': locator,
            'level': 'reviewed_non_normative_official_hosted_tutorial', 'fact': fact}

def basis(rule):
    result = raw_basis(rule)
    if rule in ('WIRE.FIELD_RANGE', 'WIRE.ANNOUNCE', 'WIRE.RESPONSE', 'WIRE.TIMESTAMP'):
        result['input_surface'] = 'typed_api_encode'
        result['precise_basis_classification'] = 'typed_protocol_representation_boundary'
    elif rule == 'WIRE.BODY_KIND':
        result['input_surface'] = 'typed_api_encode'
        result['precise_basis_classification'] = 'project_typed_input_variant_policy'
    elif rule == 'WIRE.HEX':
        result['input_surface'] = 'text_hex_adapter'
        result['precise_basis_classification'] = 'project_text_representation_policy'
    elif rule.startswith('WIRE.'):
        result['input_surface'] = 'wire_payload_decode'
        result['precise_basis_classification'] = result['classification']
    else:
        result['precise_basis_classification'] = result['classification']
    if rule.startswith('BMCA.DIFFERENT_GM.'):
        result['official'].append(tutorial_fact(
            'Pages 54 and 61; different-grandmaster dataset comparison',
            'The tutorial gives priority1, clockClass, clockAccuracy, offsetScaledLogVariance, priority2, clockIdentity precedence. The first smaller differing field wins without topology preference. This is corroboration, not the licensed normative flowchart.'))
    if rule.startswith('BMCA.SAME_GM.'):
        reviewed = {
          'BMCA.SAME_GM.stepsRemoved': 'A+1<B selects A and A>B+1 selects B, without topology preference.',
          'BMCA.SAME_GM.oneHop': 'For a one-hop difference, compare the longer path receiver with its sender: receiver<sender selects the shorter path ordinarily; receiver>sender selects the shorter path by topology.',
          'BMCA.SAME_GM.error1': 'For a one-hop difference, equality of the longer path receiver and sender is error-1.',
          'BMCA.SAME_GM.sender': 'At equal stepsRemoved, the smaller sender PortIdentity is preferred by topology.',
          'BMCA.SAME_GM.receiverPort': 'At equal stepsRemoved and sender identity, the smaller receiver port number is preferred by topology.',
          'BMCA.SAME_GM.error2': 'Equal stepsRemoved, sender identity and receiver port number reaches error-2.',
        }
        result['official'].append(tutorial_fact('Page 62; same-grandmaster dataset comparison, independently rendered and visually reviewed', reviewed[rule] + ' The tutorial corroborates this implemented branch; it is not full normative text or a port-state algorithm certificate.'))
    if rule in ('WIRE.NANOSECONDS', 'WIRE.TIMESTAMP', 'WIRE.FIELD_RANGE',
                'WIRE.RESPONSE', 'WIRE.ANNOUNCE', 'WIRE.FIXED_BODY',
                'MEASUREMENT.E2E', 'SCOPE.CORRECTION_TOO_BIG'):
        result['official'].append(tutorial_fact(
            'Page 45; timestamp and correctionField representation',
            'Timestamp uses unsigned 48-bit seconds and unsigned 32-bit nanoseconds; correctionField is signed Integer64 in 2^-16 nanoseconds. This page does not establish the nanoseconds<1e9 constraint, all typed ranges, the measurement formula or a unique tooBig sentinel.'))
    for fact in result['official']:
        source_id = SOURCE_BY_TITLE[fact['source']]
        registration = SOURCE_REGISTER[source_id]
        fact.update({'source_id': source_id, 'url': registration['url'],
                     'sha256': registration['sha256'],
                     'source_type': registration['source_type'],
                     'complete_normative_standard': registration['complete_normative_standard'],
                     'registration_record': registration['registration_record'],
                     'licence_boundary': registration['licence_boundary']})
        if 'source_access_record' in registration:
            fact['source_access_record'] = registration['source_access_record']
    result['basis_boundary'] = 'Only the specifically reviewed fact and its evidence tier are asserted. A locator, tutorial or independent implementation is not promoted to full normative-clause verification.'
    if not result['official']:
        result['local_policy_record'] = 'docs/rules.md'
    return result

def run():
    source_snapshot = [{'path': str(p.relative_to(ROOT)), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in SOURCES]
    locations = defaultdict(list)
    for p in SOURCES:
        for number, line in enumerate(p.read_text().splitlines(), 1):
            for name in PATTERN.findall(line):
                if name != 'BMCA.DIFFERENT_GM.':
                    locations[name].append({'path': str(p.relative_to(ROOT)), 'line': number})
    for field in ('priority1', 'clockClass', 'clockAccuracy', 'offsetScaledLogVariance', 'priority2'):
        line_number = next(i for i, line in enumerate((ROOT / 'bmca/bmca.mbt').read_text().splitlines(), 1) if '"BMCA.DIFFERENT_GM."' in line)
        locations['BMCA.DIFFERENT_GM.' + field].append({'path': 'bmca/bmca.mbt', 'line': line_number, 'dynamic_suffix': field})
    missing = set(locations) - set(CONDITIONS)
    assert not missing, f'Missing predicate descriptions: {sorted(missing)}'
    assert not set(CONDITIONS) - set(locations), 'Inventory contains stale rule identifiers'
    manifest = json.loads((ROOT / 'fixtures/manifest.json').read_text())
    vectors = json.loads((ROOT / 'research/implementation-reference/bmca-vectors.json').read_text())
    coverage = defaultdict(list)
    summaries = []
    operational = json.loads((ROOT / 'fixtures/commissioning/manifest.json').read_text())
    for row in [*manifest['cases'], *operational['cases']]:
        command = row.get('command', 'check')
        result = subprocess.run([str(ROOT / 'bin/ptp-audit.mjs'), command, str(ROOT / row['path']), '--json'], cwd=ROOT, capture_output=True, text=True, check=False)
        report = json.loads(result.stdout)
        assert report['status'] == row['status'], f'Unexpected fixture verdict: {row["path"]}'
        assert hashlib.sha256((ROOT / row['path']).read_bytes()).hexdigest() == row['sha256'], f'Fixture hash mismatch: {row["path"]}'
        assert row['rule'] in [f['rule'] for f in report['findings']], f'Expected rule missing: {row["path"]}'
        assert result.returncode == {'Pass': 0, 'Violation': 1, 'InsufficientEvidence': 3, 'Unsupported': 4}[row['status']], f'Unexpected CLI exit: {row["path"]}'
        found = sorted(set((f['rule'], f['status']) for f in report['findings']))
        summaries.append({'fixture': row['path'], 'command': command, 'sha256': hashlib.sha256((ROOT / row['path']).read_bytes()).hexdigest(), 'exit_code': result.returncode, 'status': report['status'], 'rules': [{'rule': r, 'status': s} for r, s in found]})
        for rule, status in found:
            coverage[rule].append({'fixture': row['path'], 'status': status})
    unexpected = set(coverage) - set(locations)
    assert not unexpected, f'Runtime rule IDs absent from source inventory: {sorted(unexpected)}'
    tests = [p for d in ('tests','wire','exchange','bmca','observation','audit','evidence','metrology','commissioning') for p in (ROOT / d).glob('*.mbt') if 'test' in p.name]
    rules = []
    for name in sorted(locations):
        evidence = basis(name)
        static_tests = []
        for p in tests:
            for line_no, line in enumerate(p.read_text().splitlines(), 1):
                if '"' + name + '"' in line:
                    static_tests.append({'path': str(p.relative_to(ROOT)), 'line': line_no, 'level': 'static_assertion_or_fixture_reference_not_execution_claim'})
        ref_vectors = [v['name'] for v in vectors['vectors'] if v.get('rule') == name]
        item = {'rule': name, 'implemented_predicates': CONDITIONS[name], 'implementation': locations[name], 'basis': evidence,
                'normative_review_state': 'local_policy_not_an_ieee_shall' if evidence['classification'].startswith('project_') else 'public_evidence_reviewed_full_text_unverified',
                'independent_vectors': {'source': 'research/implementation-reference/bmca-vectors.json' if ref_vectors else None, 'names': ref_vectors},
                'cli_observed_fixtures': coverage.get(name, []), 'static_test_mentions': static_tests,
                'coverage_boundary': 'Runtime CLI coverage names observed rule/status pairs; it is not condition/branch coverage. Static test mentions are not fresh execution proof.'}
        if name.endswith('_WINDOW') or name in ('EXCHANGE.WINDOW','EXCHANGE.STATE.CONTEXT','BMCA.SNAPSHOT.WINDOW'):
            item['shared_observation_predicates'] = GROUP_PREDICATE
        if name.startswith('BMCA.'):
            item['implementation_reference'] = {'path': 'research/implementation-reference/linuxptp-v4.4-bmc.c', 'symbols': ['dscmp', 'dscmp2'], 'boundary': 'Independent C algorithm reference; not normative text.'}
        elif name.startswith(('CLAIM.', 'EXCHANGE.', 'MEASUREMENT.')):
            item['implementation_reference'] = {'path': 'research/implementation-reference/linuxptp-v4.4-port.c', 'symbols': ['process_sync','process_follow_up','process_delay_resp','port_synchronize'], 'boundary': 'Implementation comparison only; local observation policies are independent.'}
        elif name.startswith('WIRE.'):
            item['independent_wire_evidence'] = {'path': 'research/wire-reference/verification.json', 'field_checks': 130, 'boundary': 'Six fixed payloads and five message types; does not validate all rejection paths or normative constraints.'}
        rules.append(item)
    assert source_snapshot == [{'path': str(p.relative_to(ROOT)), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in SOURCES], 'Production sources changed during CLI evidence collection; regenerate after edits finish'
    results = {'schema': 'ptp-audit/implemented-rule-inventory/v1', 'generated_at_utc': datetime.now(timezone.utc).isoformat(),
               'scope': 'Implemented bounded IEEE1588-2008 default multicast E2E two-step fixed-body encoding, association, measurement and conditional BMCA dataset comparison, plus its local evidence/input policies.',
               'method': 'Scan production rule identifiers, manually describe each implemented predicate, execute every shipped CLI fixture, link separately compiled LinuxPTP reference vectors and reviewed public-source facts.',
               'certification': 'No IEEE certification or full-protocol conformance is asserted.',
               'reference_sources': [{'source_id': source_id, **entry} for source_id, entry in SOURCE_REGISTER.items()],
               'sources': source_snapshot, 'sources_unchanged_during_run': True,
               'generator': {'path': str(Path(__file__).relative_to(ROOT)), 'sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},
               'rule_count': len(rules), 'cli_fixture_count': len(summaries), 'cli_observed_rule_count': len(coverage),
               'independent_bmca_vector_count': vectors['vector_count'], 'rules': rules,
               'actual_cli_runs': summaries,
               'review_findings': [
                   {'topic': 'same-GM one-hop direction', 'result': 'corroborated_by_independent_implementation_and_non_normative_tutorial', 'finding': 'Shorter stepsRemoved wins. longer.receiver > longer.sender means topology=true. Both orderings and error1 equality appear in separately compiled LinuxPTP vectors. Independently rendered and visually reviewed Garner tutorial p62 corroborates all same-GM branches; it remains a non-normative official-hosted tutorial.'},
                   {'topic': 'twoStepFlag applicability', 'result': 'partial_official_support', 'finding': 'Official interpretation directly confirms Follow_Up=FALSE. The implementation also requires FALSE for Delay_Req/Delay_Resp/Announce; full Table20 applicability must be verified before promoting this to fully clause-reviewed.'},
                   {'topic': 'control values', 'result': 'independent_tool_and_reference_support', 'finding': '0/1/2/3/5 and common offsets match independent fixtures/TShark and LinuxPTP layouts. Complete normative control enumeration remains to be reviewed.'},
                   {'topic': 'correction sentinel', 'result': 'explicit_conservative_scope', 'finding': 'INT64_MAX and -1 are excluded as Unsupported, not Violation. Public interpretation responses conflict; no unique sentinel resolution is asserted.'},
                   {'topic': 'sequence and identity', 'result': 'bounded_matching_confirmed', 'finding': 'Associations use equality of domain/source/sequence and requester fields. No numeric sequence ordering crosses rollover. Epoch/window are supplied capture context; Delay_Req target master is an explicit claim.'},
                   {'topic': 'field applicability completeness', 'result': 'not_a_complete_clause13_auditor', 'finding': 'Remaining semantic enumerations, all message-specific flag/reserved-field conditions, sender initialization fields and logMessageInterval values are not exhaustively validated. WIRE.FIXED_BODY means only implemented checks passed.'},
               ]}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'rule-inventory.json').write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n')
    lines = ['# 实际实现规则逐项清单', '',
             f'本清单包含 {len(rules)} 个实际规则标识；逐个执行 {len(summaries)} 个固定 CLI 案例，实际触发 {len(coverage)} 个规则标识，并关联 {vectors["vector_count"]} 个独立编译 LinuxPTP C 比较向量。清单内同时包含协议条件、项目范围和证据政策，不能把总规则数称为 IEEE 条款数。', '',
             '生成命令：`python3 research/normative-completion/build_rule_inventory.py`。机器可读版本见 [rule-inventory.json](rule-inventory.json)。每条记录包含实际断言、源码行号、源码 SHA-256、公开官方依据、尚未证实的规范条件、实际触发 fixture 及独立 vector 名称。', '',
             '每条公开来源依据均携带稳定 source_id、官方 URL、实际文档 SHA-256 和登记记录。新增 Garner 教程的第45页用于字段表示、第54/61页用于质量比较顺序、第62页用于逐分支 same-GM 方向旁证；教程仍标为非规范资料。完整 PDF 不随项目再分发，详见 [来源访问记录](source-access.md)。', '',
             '这里的 fixture 覆盖是本次实际 CLI 的规则/状态覆盖，不是全部条件或分支覆盖；静态测试位置仅是定位，不能充当本次测试通过记录。完整后端测试结果仍以项目验收记录为准。', '',
             '| 规则 | 当前实际检查 | 实际 CLI 规则触发 | 独立 C 向量 | 依据类别 |', '|---|---|---:|---:|---|']
    for item in rules:
        lines.append(f'| `{item["rule"]}` | {item["implemented_predicates"][0]} | {len(item["cli_observed_fixtures"])} | {len(item["independent_vectors"]["names"])} | {item["basis"]["classification"]} |')
    lines += ['', '## 重点审查结果', '']
    for f in results['review_findings']:
        lines += [f'- **{f["topic"]}**：{f["finding"]}']
    lines += ['', '## 不能用清单掩盖的限制', '',
              '当前完整 IEEE/IEC 许可正文尚未纳入逐页复核。公开官方解释已经确认的内容，与仅有目录定位、LinuxPTP/TShark 实现旁证、以及项目自行规定的 epoch/window/timeout 政策在 JSON 中分开记录。填齐实现规则清单不等于完成未读正文的验证，也不等于全协议认证。', '',
              '尚未由 CLI fixture 直接触发的规则也保留在清单中；其中 typed API 范围检查、资源上限和少数异常分支可能只在 MoonBit 测试中覆盖。不可从 CLI 汇总缺少某规则，反向推断它没有实现；同样不可把静态出现规则字符串算作执行通过。', '']
    (OUT / 'rule-inventory.md').write_text('\n'.join(lines))
    print(json.dumps({'rules': len(rules), 'cli_fixtures': len(summaries), 'cli_rules': len(coverage), 'files': ['research/normative-completion/rule-inventory.json','research/normative-completion/rule-inventory.md']}, ensure_ascii=False))

if __name__ == '__main__':
    run()
