# NOTES: running status

Branch `sh/foundation`. Plan and docs: [docs/sleepless-hollow/](docs/sleepless-hollow/README.md).
This file is fork-only; it holds what's done, what's next and open questions.
Update it after each milestone.

## Current stage

Stage 0: archive and baseline. Waiting on the Codex review.

## Done

- 2026-11-02: Committed the uncommitted modular proposal drafts on
  `codex/headless-lifecycle` (`53d8240`). Tagged them as
  `archive/headless-in-keepresso-2026-11-02`.
- 2026-11-02: Created `sh/foundation` from `upstream/main` `7ea73a6`.
- 2026-11-02: Wrote the planning set in `docs/sleepless-hollow/`.
- 2026-11-02: Revised the plan per decision P7. The Keepresso adapter is built
  while modularizing the rules and observations, one condition at a time.
  Keepresso's helper is left alone until Stage E.

## Next

1. Codex writes `docs/sleepless-hollow/CODEX-REVIEW.md` per CODEX-BRIEF.md.
2. jbrest settles disagreements, and the docs are updated.
3. Capture the upstream baseline: `swift build`, `swift test` pass count,
   toolchain, SDK and macOS. Record it below.
4. Stage A step 1: scaffolding. Step 2: power source, the pattern-setting move.

## Review checkpoints (Claude Code)

Stop and ask jbrest for a Claude Code review at each of these points:

1. After CODEX-REVIEW.md is written, before the docs are changed.
2. After Stage A step 2 (power source moved and adapted). This sets the pattern
   for every later condition.
3. At the end of Stage A.
4. After B1 results, before PowerControl is built.
5. Before any installed test in Stage D.
6. Any time an invariant in MIGRATION-PLAN.md would have to be broken, or an
   approach has failed twice.

## Baseline

Not yet captured.

## Open questions

See [DECISIONS.md](docs/sleepless-hollow/DECISIONS.md), section "Open". The
ones that block early stages:
- O11: fill in the two-state mapping table as each condition moves (Stage A).
- O5: console-session detection method (Stage A step 7).
- O1: power mechanism (B1, which needs jbrest for reboots and logouts).

## Watch

- Upstream PR #31 reworks `SessionController`. It doesn't touch the files Stage
  A moves, and jbrest has said it is not a concern.
- Nothing on `sh/foundation` or the archive tag has been pushed to `origin`.
