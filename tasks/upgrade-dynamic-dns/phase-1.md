# Phase 1 — Refactor Dynamic DNS Script

## Objective
Update `network-routing/dynamic_dns.py` so the runtime path uses the required env inputs, the current Cloudflare bearer-token DNS record API flow, and explicit fail-fast handling for invalid responses and update failures.

## Code areas impacted
- `network-routing/dynamic_dns.py`

## Work items
- [x] Require `CFBEARER`, `CFACC`, and `CFZONE` from the env file and preserve the existing CLI shape.
- [x] Refactor request helpers so list and patch operations parse Cloudflare envelopes consistently and surface actionable errors.
- [x] Constrain record updates to the records relevant for the provided IP version and skip records that already match.
- [x] Keep secret handling minimal and avoid logging credential values.

## Deliverables
- Updated `network-routing/dynamic_dns.py` with stricter validation, record filtering, and Cloudflare request handling.

## Gate (must pass before proceeding)
Define objective pass/fail criteria.
- [x] The script has the required env validation and bounded update behavior without changing locked scope or CLI usage.

## Verification steps
List exact commands and expected results.
- [x] Command: `python3 -m py_compile network-routing/dynamic_dns.py`
  - Expected: `passes with no syntax errors`

## Risks and mitigations
- Risk: over-filtering records could stop intended updates.
- Mitigation: filtering is bound to the provided IP version and is covered by the unit test plan executed in Phase 2.
