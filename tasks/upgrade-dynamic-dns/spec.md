# Upgrade Dynamic DNS

## Overview
Upgrade `network-routing/dynamic_dns.py` to use the current Cloudflare bearer-token DNS record API flow while preserving the existing CLI shape and tightening failure handling.

## Goals
- Require `CFBEARER`, `CFACC`, and `CFZONE` in the env file and fail explicitly when any value is missing or empty.
- Align the script with the current Cloudflare DNS record API flow used for listing and patching DNS records.
- Preserve the dynamic DNS workflow so only records that need the target IP are updated.
- Improve fail-fast handling for HTTP failures, malformed Cloudflare responses, and unsuccessful API results.
- Add automated verification for env parsing and Cloudflare request/update behavior without live API calls.

## Non-goals
- Do not change unrelated repository areas outside the dynamic DNS script and directly required verification artifacts.
- Do not broaden the tool into general DNS management beyond the requested Cloudflare credential/API upgrade and robustness fixes.

## Use cases / user stories
- An operator runs `python3 network-routing/dynamic_dns.py <IP> <ENV_FILE>` to synchronize the zone’s dynamic DNS records to a new IP.
- An operator receives a clear non-zero failure when the env file is incomplete or Cloudflare rejects the request.
- A maintainer can verify the behavior locally with automated tests that do not depend on live Cloudflare access.

## Current behavior
- Notes:
  - The script currently requires `CFBEARER` and `CFZONE`, but does not validate `CFACC`.
  - It lists all zone DNS records and attempts to patch every record whose `content` differs from the provided IP.
  - HTTP and API error handling is inconsistent and contains malformed result access in the patch path.
- Key files:
  - `network-routing/dynamic_dns.py`

## Proposed behavior
- Behavior changes:
  - Require `CFBEARER`, `CFACC`, and `CFZONE` in the env file.
  - Keep Cloudflare authentication on bearer-token headers and use the current zone-scoped DNS record list/edit endpoints.
  - Restrict updates to records relevant to the provided IP version and skip records already set to the target IP.
  - Surface deterministic errors for request failures, malformed responses, and unsuccessful Cloudflare result envelopes.
  - Add unit tests for env parsing, record filtering, and request/update behavior.
- Edge cases:
  - Missing or empty env values.
  - Mixed DNS record types in the zone.
  - Already-matching records that should not be patched.
  - Non-success Cloudflare responses with HTTP success status.

## Technical design
### Architecture / modules impacted
- `network-routing/dynamic_dns.py`
- `tests/test_dynamic_dns.py`

### API changes (if any)
- No CLI shape change is planned.
- The env-file contract is tightened to require `CFACC` in addition to `CFBEARER` and `CFZONE`.

### UI/UX changes (if any)
- None.

### Data model / schema changes (PostgreSQL)
- Migrations: None.
- Backward compatibility: Existing CLI invocation remains unchanged.
- Rollback: Revert the script and test changes.

## Security & privacy
- Keep the bearer token sourced from the env file only.
- Do not log secret values.
- Fail explicitly on auth or API envelope errors instead of masking them.

## Observability (logs/metrics)
- Standard error output remains the primary operational signal.
- Error messages should identify the failed request stage and reason without exposing secrets.

## Verification Commands
> Pinned for this task using the local Python runtime discovered in Stage 2.

- Lint:
  - `python3 -m py_compile network-routing/dynamic_dns.py tests/test_dynamic_dns.py`
- Build:
  - `python3 -m compileall -q network-routing tests`
- Test:
  - `python3 -m unittest -q tests.test_dynamic_dns`

## Test strategy
- Unit:
  - Env parsing and required-variable validation.
  - Record selection and no-op behavior for already-matching records.
  - Cloudflare list/edit request handling with mocked HTTP responses.
- Integration:
  - None planned; live Cloudflare API calls are out of scope.
- E2E / UI (if applicable):
  - Not applicable.

## Acceptance criteria checklist
- [x] Locked goals are copied into this spec without expansion.
- [x] Verification commands are pinned for lint, build, and test.
- [x] Scope boundaries and execution posture are explicitly recorded.
- [x] Ambiguity check passed; no blocking questions remain.

## IN SCOPE
- `network-routing/dynamic_dns.py`
- `tests/test_dynamic_dns.py`
- Task and goal artifacts required by the lifecycle workflow for `upgrade-dynamic-dns`

## OUT OF SCOPE
- Other scripts under `network-routing/` or elsewhere in the repository
- Live Cloudflare integration testing or operational env-file content changes
- New dependencies, new services, or changes to repository-wide tooling conventions

## Goal lock assertion
- Locked goals source: `goals/upgrade-dynamic-dns/goals.v0.md`
- Goals, constraints, and success criteria are approved and immutable for downstream stages.

## Ambiguity check
- Result: passed
- Notes: no blocking ambiguity remains; `CFACC` will be treated as a required env input even though the Cloudflare DNS record edit endpoint is zone-scoped.

## Governing context
- Rules:
  - `codex/rules/expand-task-spec.rules`
  - `codex/rules/git-safe.rules`
- Skills:
  - `acac`
  - `prepare-takeoff`
  - `prepare-phased-impl`
  - `implement`
  - `land-the-plan`
- Sandbox:
  - `workspace-write`
  - network restricted

## Existing-worktree safety prep
- `prepare-takeoff-worktree.sh upgrade-dynamic-dns` completed on branch `main`.
- `git worktree prune` ran successfully.
- No merge conflicts were present.
- Uncommitted entries at Stage 2 were limited to new lifecycle artifacts under `goals/` and `tasks/`.

## Execution posture
- Simplicity bias: locked
- Surgical-change rule: locked
- Fail-fast error handling: locked

## Change control
- Goal, constraint, success-criteria, and scope changes are not allowed without re-entering the lifecycle at the appropriate gate.
- Override authority: explicit user approval plus the required lifecycle relock.

## Stage 2 Verdict
- Verdict: READY FOR PLANNING

## Implementation phase strategy
- Complexity: scored:L2 (focused)
- Complexity scoring details: score=8; recommended-goals=4; guardrails-all-true=true; signals=/Users/eric/side-projects/helpers/tasks/upgrade-dynamic-dns/complexity-signals.json
- Active phases: 1..3
- No new scope introduced: required
