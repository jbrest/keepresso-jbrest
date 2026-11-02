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
- 2026-11-02: Wrote the planning set in `docs/sleepless-hollow/`: README,
  ARCHITECTURE, MIGRATION-PLAN, SOURCE-INVENTORY, DECISIONS, PRODUCT (carried
  forward), VALIDATION (carried forward), CODEX-BRIEF.

## Next

1. Codex writes `docs/sleepless-hollow/CODEX-REVIEW.md` per CODEX-BRIEF.md.
2. jbrest settles disagreements, and the docs are updated.
3. Capture the upstream baseline: `swift build`, `swift test` pass count,
   toolchain, SDK and macOS. Record it below.
4. Start Stage A1 (RuleModel and RuleEvaluation).

## Baseline

Not yet captured.

## Open questions

See [DECISIONS.md](docs/sleepless-hollow/DECISIONS.md), section "Open". The
ones that block early stages:
- O5: console-session detection method (A2).
- O1: power mechanism (B1, which needs jbrest for reboots and logouts).

## Watch

- Upstream PR #31 (alvst, "Make manual and automatic session activity clearer",
  +2,464/-484) reworks `SessionController`. It does not affect Stages A to D. It
  gates Stage G.
- Nothing on `sh/foundation` or the archive tag has been pushed to `origin`.
