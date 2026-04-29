# Revalidate Code Review
- Task name: upgrade-dynamic-dns
- Findings status: none

## Reviewer Prompt
You are acting as a reviewer for a proposed code change made by another engineer.
Focus on issues that impact correctness, performance, security, maintainability, or developer experience.
Flag only actionable issues introduced by the pull request.
When you flag an issue, provide a short, direct explanation and cite the affected file and line range.
Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff.
After listing findings, produce an overall correctness verdict ("patch is correct" or "patch is incorrect") with a concise justification and a confidence score between 0 and 1.
Ensure that file citations and line numbers are exactly correct using the tools available; if they are incorrect your comments will be rejected.

## Output Schema
```json
[
  {
    "file": "path/to/file",
    "line_range": "10-25",
    "severity": "high",
    "explanation": "Short explanation."
  }
]
```

## Review Context (auto-generated)
<!-- REVIEW-CONTEXT START -->
- Generated at: 2026-04-29T04:47:16Z
- Base branch: main
- Diff mode: fallback
- Diff command: `git diff`
- Diff bytes: 49862

### Changed files
- `goals/task-manifest.csv`
- `goals/upgrade-dynamic-dns/establish-goals.v0.md`
- `goals/upgrade-dynamic-dns/goals.v0.md`
- `network-routing/dynamic_dns.py`
- `tasks/upgrade-dynamic-dns/.complexity-lock.json`
- `tasks/upgrade-dynamic-dns/.scope-lock.md`
- `tasks/upgrade-dynamic-dns/complexity-signals.json`
- `tasks/upgrade-dynamic-dns/final-phase.md`
- `tasks/upgrade-dynamic-dns/lifecycle-state.md`
- `tasks/upgrade-dynamic-dns/phase-1.md`
- `tasks/upgrade-dynamic-dns/phase-2.md`
- `tasks/upgrade-dynamic-dns/phase-3.md`
- `tasks/upgrade-dynamic-dns/phase-plan.md`
- `tasks/upgrade-dynamic-dns/revalidate-code-review.md`
- `tasks/upgrade-dynamic-dns/risk-acceptance.md`
- `tasks/upgrade-dynamic-dns/spec.md`
- `tests/__init__.py`
- `tests/test_dynamic_dns.py`

### Citation candidates (verify before use)
- `goals/task-manifest.csv:1-2`
- `goals/upgrade-dynamic-dns/establish-goals.v0.md:1-78`
- `goals/upgrade-dynamic-dns/goals.v0.md:1-30`
- `network-routing/dynamic_dns.py:1-3`
- `network-routing/dynamic_dns.py:121-152`
- `network-routing/dynamic_dns.py:155-156`
- `network-routing/dynamic_dns.py:159-164`
- `network-routing/dynamic_dns.py:166-211`
- `network-routing/dynamic_dns.py:214-214`
- `network-routing/dynamic_dns.py:216-216`
- `network-routing/dynamic_dns.py:224-226`
- `network-routing/dynamic_dns.py:229-229`
- `network-routing/dynamic_dns.py:26-27`
- `network-routing/dynamic_dns.py:30-30`
- `network-routing/dynamic_dns.py:33-33`
- `network-routing/dynamic_dns.py:36-36`
- `network-routing/dynamic_dns.py:40-42`
- `network-routing/dynamic_dns.py:47-50`
- `network-routing/dynamic_dns.py:5-5`
- `network-routing/dynamic_dns.py:52-54`
- `network-routing/dynamic_dns.py:58-63`
- `network-routing/dynamic_dns.py:66-88`
- `network-routing/dynamic_dns.py:8-13`
- `network-routing/dynamic_dns.py:90-119`
- `tasks/upgrade-dynamic-dns/.complexity-lock.json:1-23`
- `tasks/upgrade-dynamic-dns/.scope-lock.md:1-9`
- `tasks/upgrade-dynamic-dns/complexity-signals.json:1-24`
- `tasks/upgrade-dynamic-dns/final-phase.md:1-45`
- `tasks/upgrade-dynamic-dns/lifecycle-state.md:1-4`
- `tasks/upgrade-dynamic-dns/phase-1.md:1-29`
- `tasks/upgrade-dynamic-dns/phase-2.md:1-30`
- `tasks/upgrade-dynamic-dns/phase-3.md:1-34`
- `tasks/upgrade-dynamic-dns/phase-plan.md:1-31`
- `tasks/upgrade-dynamic-dns/revalidate-code-review.md:1-103`
- `tasks/upgrade-dynamic-dns/risk-acceptance.md:1-11`
- `tasks/upgrade-dynamic-dns/spec.md:1-149`
- `tests/__init__.py:1-1`
- `tests/test_dynamic_dns.py:1-150`
<!-- REVIEW-CONTEXT END -->

## Findings JSON
```json
[]
```

## Overall Correctness Verdict
- Verdict: patch is correct
- Confidence: 0.87
- Justification: The patch tightens the Cloudflare env contract, constrains updates to records that match the supplied IP version, preserves record metadata in PATCH payloads, and adds isolated tests for the new success and failure paths without introducing scope drift.
