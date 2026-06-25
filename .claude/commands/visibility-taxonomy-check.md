---
description: Verify visibility taxonomy (ADR-020) is two-valued (`public` / `enterprise-private`) and not conflated with license taxonomy (ADR-023, three-valued).
argument-hint: ADR / doc / cap description that mentions visibility or license
---

Audit this visibility / license claim.

Visibility taxonomy (ADR-020, two-valued):
- `public` — open documentation, public ADRs, public repos.
- `enterprise-private` — closed documentation, content private, but the ADR NUMBER is still publicly registered in `adr-index.md`.
- `public-staged` — **DEPRECATED**. Flag any reintroduction.

License taxonomy (ADR-023, three-valued, SEPARATE AXIS — applies to capability artefacts, NOT to ADR files):
- `community` — Apache 2.0 / MIT — 3 caps (`cors-policy`, `i18n`, `observability-bridge`).
- `commercial` — Exeris Commercial License (source-available, BSL-style) — 46 caps (the bulk of Tier 2).
- `enterprise-private` — closed-source, Enterprise tier only — 1 cap (`bot-fingerprinting`).

SKU repository source-visibility (ADR-023 same-day amendment 2026-05-13):
- 6/7 Platform SKUs are **source-available** public repos under Exeris Commercial License (API Gateway, Edge Proxy, IDP, PIM, OMS, Headless CMS API).
- 1/7 Platform SKU is **closed-source** on anti-abuse-security principle: Bot Blocker (named exception, principled — published detection helps adversaries).

Change:
$ARGUMENTS

Please review:
1. If visibility is mentioned: is it `public` or `enterprise-private`? Any `public-staged` reintroduction is a hard reject.
2. If license is mentioned: is the three-valued ADR-023 taxonomy used? Two-value taxonomy is wrong.
3. Are visibility and license treated as orthogonal axes (not conflated)?
4. For caps: is the license value plausible (most caps `commercial`; only 3 `community`; only 1 `enterprise-private`)?
5. For SKUs: is the 6/7 source-available vs 1/7 closed-source (Bot Blocker named exception) framing respected?
6. Minimal correction if taxonomy is at risk.

Don't conflate visibility (where the doc lives) with license (what the code is licensed under).
