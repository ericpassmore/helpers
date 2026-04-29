# Goals Extract
- Task name: upgrade-dynamic-dns
- Iteration: v0
- State: locked

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

