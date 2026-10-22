# IEEE 1588-2008 / IEC 61588 evidence register

This directory deliberately stores short factual notes and hashes only. It does not redistribute the IEEE/IEC standard text or the full IEEE interpretation document. URLs below are official publisher/standards-body locations; access and licensing may change. The project must cite the standard or licensed copy for a formal conformance claim.

## Official sources

| source | URL | observed SHA-256 (local evidence download, not bundled) | use and limits |
|---|---|---|---|
| IEEE Standards Interpretations for IEEE Std 1588-2008 (Dec 2011, 29 pages) | https://standards.ieee.org/wp-content/uploads/import/documents/interpretations/1588-2008_interp.pdf | `fae8481cbaad0657d6e094a789cbf15afe57850991271d90fb9cdddc3fdb3bb5` | Official clarifications; not a replacement for the licensed standard. Download/printing permission appears on its copyright page; redistribution of the full document is restricted. |
| IEC 61588:2009 preview (IEEE 1588-2008 under IEC licence) | https://webstore.iec.ch/en/iec_catalog/product/preview/?id=L3B1Yi9wZGYvcHJldmlldy9pbmZvX2llYzYxNTg4e2VkMi4wfWVuLnBkZg== | `e33a07902fcd4ea7812dc09cdb9be66f3cc72c71f38990fe531ea1a8c08ca439` | Official preview only; it exposes the table of contents and selected preview pages, not the complete standard. |
| IEEE 802.1 public contribution, 1588 header/reserved-field proposal (Mar 2015) | https://www.ieee802.org/1/files/public/docs2015/as-cummings-1588-upkeep-work-item-89-0315-v1.pdf | `862d9ea35675a982bf473ebfe0e3aa728286ffdd8cd32325acdcd9a2a14458db` | Official working-group contribution, not a normative standard. It reproduces Table 18 layout and discusses 4.2.8/13.2 reserved-field behavior. |
| NIST IEEE 1588 tutorial (2005, pre-2008 tutorial) | https://www.nist.gov/system/files/documents/el/isd/ieee/tutorial-basic.pdf | `not retained in project; fetched separately` | Government background/tutorial only; it is not evidence for 2008 byte-level conformance. |

## Facts that are safe to cite from the observed official documents

* IEC preview contents identify Clause 13 PTP message formats and Table 18 (common header), Table 25 (Announce), Table 26 (Sync and Delay_Req), Table 27 (Follow_Up), and Table 28 (Delay_Resp). The preview does not expose every field value; do not claim complete normative verification from the contents page.
* IEEE interpretation #2 (page 3) discusses `clockIdentity`/`portIdentity` comparison under subclause 7.5.2.4 and says that when a `PortIdentity` is compared with a `ClockIdentity`, the absent `portNumber` is treated as zero for that comparison.
* IEEE interpretation #3 (page 3) says `announceReceiptTimeout` is configurable in the range 2–255 (profiles may choose a default; 3 is recommended in the interpretation). This is relevant to a capture-window policy, but does not itself define this project's offline JSON window.
* IEEE interpretation #11 (page 7) resolves the two-step wording conflict: the Follow_Up header copies Sync flags with `twoStepFlag` set to FALSE, while a two-step Sync indicates a following Follow_Up. This confirms that a non-Sync `twoStepFlag` is not interchangeable with a two-step Sync assertion.
* IEEE interpretation #21 (pages 14–15) restates 7.5.2.3: port numbers are 1, 2, …, N where N is `defaultDS.numberPorts`; it also notes static dataset constraints from 8.2.1.2.3 and 8.2.5.2.1. It is not evidence that 65535 is a valid ordinary source port in every profile.
* IEEE interpretation #25 (page 21) says `correctionField` is an Integer64 and can represent negative values; it describes a distinguished too-big value as `0x7fffffffffffffff` in that response. Interpretation #27 (pages 23–24) separately says all bits one (`0xffffffffffffffff`) is reserved as too-big. These two official responses conflict. The implementation must document its conservative handling and must not claim that either sentinel is the unambiguous 2008 rule without licensed-standard/errata review.
* IEEE interpretation #31 (page 28) explicitly gives the Figure 27 / Clause 9.3.4 BMCA precedence: priority1, clockClass, clockAccuracy, variance, priority2, then clockIdentity. It confirms the ordering only; topology and all decision-state semantics still require the licensed standard.
* IEEE 802.1 contribution page 2 says reserved fields are for future editions (4.2.8), transmitted as zero and ignored on receive (13.2). Page 4 reproduces the common header offsets: correctionField at offset 8 for 8 octets, sourcePortIdentity at offset 20 for 10 octets, sequenceId at offset 30 for 2 octets, controlField at offset 32, and logMessageInterval at offset 33. This is a working-group proposal/description, not a normative replacement for Table 18.

## Claims that remain unverified by these sources

The project has not obtained a complete, licensed IEEE 1588-2008 text or errata set. These sources therefore do not independently prove: every five-body byte value and length; all control-field enumerations; nanoseconds < 1e9; complete two-step E2E association rules in Clause 11; all BMCA same-grandmaster topology branches in Figures 27–28; or a profile-specific port-identity sentinel policy. Such claims must remain implementation/profile assumptions until verified against a licensed normative copy.

On 2026-10-19, a scoped filename search of existing PDF, Word and text documents in the user's Downloads, Documents and current project did not locate a complete IEEE 1588 / IEC 61588 standard. No third-party standard PDF of uncertain authorization was used. This is a recorded search result, not a claim that no licensed copy exists anywhere on the machine.

## Implemented handling of the confirmed differences

* `WIRE.TWO_STEP_FLAG` rejects a set two-step flag in supported non-Sync messages; the unsupported Pdelay_Resp case is outside this product.
* `SCOPE.CORRECTION_TOO_BIG` excludes both `0x7fffffffffffffff` and `0xffffffffffffffff` from arithmetic as a conservative scope policy while the two official interpretation responses conflict. Ordinary signed negative values remain supported. This implementation choice does not resolve the underlying normative conflict.
* A nonzero reserved field is diagnosed as a canonical transmitted-message constraint, not evidence that a receiving device was required to reject the message.
* The implemented port range 1..65535 is a nonzero UInt16 input bound. The project does not know the device's `defaultDS.numberPorts`, so acceptance does not certify that an actual port number is within 1..N on that device.
