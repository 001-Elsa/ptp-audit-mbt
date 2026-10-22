# Official normative-source access record — 2026-10-19

This record covers the access attempts below. It is not an exhaustive assertion about every library, subscription, distributor, or copy on the Internet. No standard was purchased, no new licence or terms were accepted, and no access control was bypassed. Copyrighted full documents are not included in the project archive.

The complete IEEE 1588-2008 / IEC 61588:2009 normative text has **not** been obtained through these access attempts. A public tutorial, an official interpretation, and an official preview remain distinguishable from that text.

| Official route | Actual observation | Result |
| --- | --- | --- |
| [IEEE 1588-2008 landing page](https://standards.ieee.org/ieee/1588/4355/) | Browser read successfully. It identifies a superseded standard published 2008-07-24 and exposes Purchase and Access via Subscription. Purchase leads to `https://store.accuristech.com/ieee/products/vendor_id/4355`; subscription leads to `https://innovate.ieee.org/subscriptions-for-ieee-standards-and-related-content/`. The Additional Resources section links the known interpretation PDF. | Metadata and lawful acquisition routes established; no unrestricted full-text link shown. |
| [IEEE GET Program](https://standards.ieee.org/products-programs/ieee-get-program/) | Browser read successfully. Its displayed available families are IEEE 802, Design Automation, AI Ethics and Governance, IEEE 1680, IEEE/ANSI N42, and IEEE C95. The page says only selected sponsored standards are included and requires users to accept Terms and Conditions before a PDF is permitted. | The page did not establish that IEEE 1588-2008 is covered. No terms were accepted. |
| [IEEE Xplore document 4579760](https://ieeexplore.ieee.org/document/4579760) | HTTP request returned 202 with zero response bytes; a normal browser navigation also displayed an empty document page. | No full text or valid subscription entitlement established. |
| [IEC 61588:2009 product page](https://webstore.iec.ch/en/publication/5639) | Browser read successfully. IEC identifies edition 2.0, publication 2009-02-27, ISBN 9782889105465, 287 pages, 3.80 MB, a single-user electronic price of CHF 475, and a Log in control. | The paid full edition is identified. Nothing was added to the cart or purchased. |
| [IEC official preview](https://webstore.iec.ch/en/iec_catalog/product/preview/?id=L3B1Yi9wZGYvcHJldmlldy9pbmZvX2llYzYxNTg4e2VkMi4wfWVuLnBkZg==) | The previously downloaded official preview was re-read locally: 19 pages; SHA-256 `e33a07902fcd4ea7812dc09cdb9be66f3cc72c71f38990fe531ea1a8c08ca439`. Every preview page links back to the full product. | Preview only, not the 287-page edition. |
| [IEEE Precise Networked Clock Synchronization working group](https://sagroups.ieee.org/1588/) | HTTP returned 403. | No usable new source from this request; this does not prove no public source exists elsewhere on the group's site. |
| NIST legacy ordering path, `/el/intelligent-systems-division-73500/ieee-1588/ordering-ieee-1588-standard` | HTTP returned 404. | This legacy URL was unavailable; no conclusion about other NIST paths. |

## Additional official source actually read

The publicly listed IEEE 802.1 contribution [IEEE 1588 Version 2, Geoffrey M. Garner, September 24, 2008](https://www.ieee802.org/1/files/public/docs2008/as-garner-1588v2-summary-0908.pdf) was located through a public search result and the IEEE 802.1 directory listing. The cached complete PDF was read with an independent PDF parser: **89 pages**, **3,623,113 bytes**, SHA-256 **`a023d1d55e20fe4b3ea5dbf11cdcfd650abfa071c3cab11e8247de6ff4eece68`**.

Its title and page 4 explicitly identify it as a tutorial. Public hosting by IEEE 802 is an authoritative provenance signal for the contribution, not permission to repackage it and not a conversion of the tutorial into a normative standard. A local research copy is retained outside the repository at `~/.local/share/ptp-audit-tools/standards/ieee802-garner-2008-tutorial.pdf`.

Short factual corroborations from that tutorial:

* Page 45 identifies a timestamp with unsigned 48-bit seconds and unsigned 32-bit nanoseconds; it identifies correctionField as signed Integer64 scaled in units of `2^-16` nanoseconds. It does not specify the nanosecond range or resolve tooBig encoding on that page.
* Page 54 gives the ordering priority1, clockClass, clockAccuracy, offsetScaledLogVariance, priority2, clockIdentity.
* Pages 61–62 reproduce the dataset comparison flow, including the same-grandmaster stepsRemoved, sender/receiver identity and receiver-port branches. They can be used as another independently inspected reference diagram, with the tutorial status retained in each claim.
* Pages 64–65 say that a PTP profile selects parameters, options, transport, node types and conformance procedure. A locally chosen capture timeout is not thereby an IEEE protocol timeout.

No control-field enumeration, nanosecond upper-bound clause, full Clause 11 association proof, or resolution of the conflicting correctionField interpretations was obtained from this source. These items must not be marked normatively verified solely because the tutorial was read.

## What would close full-text provenance

A legitimately licensed IEEE 1588-2008 or IEC 61588:2009 copy, supplied by the user or accessed through an already entitled institution, would permit checking the remaining actual clauses. The official IEC route is concrete and priced above; buying it or accepting a new licence was outside this read-only source-access task. Until such a source is available, a complete licensed-text review cannot truthfully be recorded as performed.

## China equivalent-adoption route actually checked

The national standard **GB/T 25931-2010, 网络测量和控制系统的精确时钟同步协议**, is an **identical adoption of IEC 61588:2009**. This is directly confirmed by the [official SAMR metadata](https://std.samr.gov.cn/gb/search/gbDetailed?id=71F772D7DBF1D3A7E05397BE0A0AB82A), which states: “本标准等同采用IEC国际标准：IEC 61588:2009。” The [official search result](https://std.samr.gov.cn/search/std?q=25931) and its public result iframe also identify that relationship. It is therefore a relevant translated equivalent edition, rather than a different 2002/2004 protocol edition.

The [official full-text system search](https://openstd.samr.gov.cn/bzgk/gb/std_list?p.p1=0&p.p90=circulation_date&p.p91=desc&p.p2=25931) returned one current item, published 2011-01-14 and effective 2011-05-01. The linked [official detail page](https://openstd.samr.gov.cn/bzgk/gb/newGbInfo?hcno=EB586F0639AD2D2B3EDA2E202211D0AC) explicitly states:

> 该标准采用了ISO、IEC等国际国外组织的标准，由于涉及版权保护问题，本系统暂不提供在线阅读服务。

Consequently, this potentially useful equivalent edition is **not offered for online full-text reading by that official route**. The generic reader JavaScript present in the website template was not invoked behind the explicit copyright restriction. The source-access JSON records the exact URLs, quoted access notice, adoption edition, HTTP result and metadata snapshot hashes. The complete Chinese standard was not obtained or bundled.


## India official-linked catalogue route actually checked

The [Bureau of Indian Standards homepage](https://www.bis.gov.in/) explicitly links **Download Indian Standards** to [standardsbis.bsbedge.com](https://standardsbis.bsbedge.com/). This establishes the destination as the download route linked by BIS. The destination identifies itself as **Bureau of Indian Standards - e-Sale** and states:

> Buy and Download Individual Indian Standards from our Website. Indigenous Indian Standards can be downloaded free of cost.

This banner does not establish that a particular IEC adoption is free. The normal public search interface was checked for the actual target:

* The observed public autocomplete service returned an empty array for `61588`, `IS/IEC 61588` and `IS 61588`. A positive control query `IS/IEC 615` returned actual 61508, 61511, 61537, 61557 and 61558 records, confirming that the service itself was responding.
* Submitting the normal **Standard Number** form with `61588` led to [the actual result URL](https://standardsbis.bsbedge.com/BIS_SearchStandard.aspx?Standard_Number=61588&id=0), HTTP 200, with the visible message **There are no results that match your search.**
* Submitting the normal **Title** form with `precise clock synchronization` led to [the actual title result URL](https://standardsbis.bsbedge.com/BIS_SearchStandard.aspx?keyword=precise%20clock%20synchronization&id=0), HTTP 200, with the same no-results message.
* The linked [FAQ](https://standardsbis.bsbedge.com/BIS_FAQ.aspx?id=faq) describes registration/login to purchase standards and login to download free amendments. No account was created, no product was purchased, and no new terms were accepted.

Consequently, these queries did **not locate an actual IS/IEC 61588 entry**, establish an identical 2009 adoption, or provide a free complete copy. There is no basis to assert a specific 61588 price or blanket copyright exclusion from the general banner alone. This result is limited to the recorded public catalogue queries; it does not prove that no Indian equivalent or institutional access route exists. The source-access JSON contains the exact queries, result URLs and snapshot hashes.

## Other official access result

A normal request to the Russian official portal `https://protect.gost.ru/` failed at DNS resolution with `URLError(gaierror(8, 'nodename nor servname provided, or not known'))`. No document was obtained through that attempt. This is an access failure for that hostname from this environment, not a conclusion about every Russian standard access route.


### Russian route: ordinary DNS repair retried

The initial system DNS failure was **not treated as a complete access investigation**. Normal public DNS queries were retried without changing the hostname, disabling TLS checks, or guessing an origin address:

| Actual query | Observed result |
| --- | --- |
| `nslookup protect.gost.ru 8.8.8.8` | Google public DNS returned `SERVFAIL`. |
| `dig +time=5 +tries=1 @1.1.1.1 protect.gost.ru A` | Cloudflare public DNS returned `SERVFAIL`, no A answer, with the extended error `at delegation gost.ru.` |
| `dig +time=5 +tries=1 @1.1.1.1 gost.ru NS +cdflag` | Even with DNSSEC checking disabled for this diagnostic query, the parent NS lookup returned `SERVFAIL`, no answer and the same delegation error. |
| `https://dns.alidns.com/resolve?name=protect.gost.ru&type=A` | HTTP 200, DNS `Status: 2` / server failure, no address. |
| Google DNS-over-HTTPS A/NS queries | Timed out. |
| Cloudflare DNS-over-HTTPS A query | Connection reset by peer. |

No resolver supplied a credible origin address, so there was no valid address to pass to `curl --resolve` while retaining normal hostname and certificate verification. This rules out relying solely on the original local resolver failure; it still does **not** establish the site's actual copyright/access policy, nor prove that a lawful equivalent text is absent elsewhere. No unofficial `docs.cntd.ru` copy was treated as authorized evidence.


Candidate government-host paths `https://www.rst.gov.ru/portal/gost/` and `/portal/gost/home/standarts` were also requested normally; both failed DNS before any page was retrieved. Their current catalogue contents or access rules were consequently not verified.
