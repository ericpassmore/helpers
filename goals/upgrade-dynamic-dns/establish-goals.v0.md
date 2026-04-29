# establish-goals

## Status

- Iteration: v0
- State: locked
- Task name (proposed, kebab-case): upgrade-dynamic-dns

## Request restatement

- Upgrade `network-routing/dynamic_dns.py` to use the current Cloudflare DNS record API contract and the provided env-file variables `CFBEARER`, `CFACC`, and `CFZONE`.

## Context considered

- Repo/rules/skills consulted:
  - `/Users/eric/side-projects/helpers/AGENTS.md`
  - `/Users/eric/.codex/skills/acac/SKILL.md`
  - `/Users/eric/.codex/skills/establish-goals/SKILL.md`
- Relevant files (if any):
  - `/Users/eric/side-projects/helpers/network-routing/dynamic_dns.py`
- Constraints (sandbox, commands, policy):
  - No source-code changes before goals lock.
  - Goal and task artifacts must be created via the approved ACAC scripts.
  - Verification will need to cover `lint`, `build`, and `test` command classes using repo/task records where available.

## Ambiguities

### Blocking (must resolve)

1. None identified.

### Non-blocking (can proceed with explicit assumptions)

1. The existing CLI contract `python dynamic_dns.py <IP> <ENV_FILE>` should remain unchanged unless implementation evidence later shows a hard requirement to alter it.
2. `CFACC` should be treated as part of the required env contract even if the Cloudflare DNS record edit endpoint remains zone-scoped and does not require `account_id` on the PATCH request itself.
3. The script should continue serving its dynamic-DNS purpose by updating only records that need the target IP, without broadening into unrelated DNS management behavior.

## Questions for user

1. No blocking questions at this stage.

## Assumptions (explicit; remove when confirmed)

1. The requested upgrade is limited to `network-routing/dynamic_dns.py` and any directly required tests or task artifacts.
2. The Cloudflare API reference supplied by the user is authoritative for this change.
3. It is acceptable to tighten validation and error reporting where the current script is permissive or malformed.

## Goals (1-20, verifiable)

1. Update `network-routing/dynamic_dns.py` to consume the env-file contract `CFBEARER`, `CFACC`, and `CFZONE`, failing explicitly when any required value is missing or empty.
2. Align the script’s Cloudflare DNS API interaction with the current official bearer-token DNS record API referenced by the user, including request headers, endpoint usage, and response handling needed for record updates.
3. Preserve the script’s core dynamic-DNS behavior: given an IP and env file, detect records that need the new IP and issue update requests only when a change is required.
4. Improve fail-fast behavior so HTTP failures, malformed Cloudflare responses, and unsuccessful API results surface clear, actionable errors instead of silent or ambiguous failures.
5. Add or update automated verification for the changed behavior, covering env parsing/validation and the Cloudflare request/update flow without making live external API calls.

## Non-goals (explicit exclusions)

- Do not change unrelated scripts or repository areas outside the dynamic DNS flow and directly necessary verification/task artifacts.
- Do not introduce new product behavior beyond the Cloudflare credential/API upgrade and robustness improvements required to support it.

## Success criteria (objective checks)

> Tie each criterion to a goal number when possible.

- [G1] Running the script with an env file missing `CFBEARER`, `CFACC`, or `CFZONE` exits with an explicit validation error.
- [G2] Automated verification shows the script builds the expected Cloudflare authenticated requests and correctly handles success and error responses for DNS record updates.
- [G3] Automated verification shows records already matching the target IP are not updated, while records requiring the new IP trigger update requests.
- [G4] Failure scenarios from Cloudflare or invalid response payloads produce deterministic non-zero exits and human-readable error output.
- [G5] The defined verification commands for this change complete successfully or any blocker is explicitly documented.

## Risks / tradeoffs

- The user-provided `CFACC` value may be required only for configuration compatibility rather than for the zone-scoped DNS edit endpoint itself, so the implementation must avoid inventing unsupported API usage just to consume the field.
- Tightening record filtering or response validation may expose latent issues in existing environments, but that is preferable to silently issuing invalid DNS updates.

## Next action

- Present extracted goals for user approval, then lock goals if approved.
