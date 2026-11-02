# Brief for Codex: review and handoff

Date: 2 November 2026. From: Claude Code, at jbrest's request.

## Context

jbrest has replaced the earlier approach. The in-Keepresso Headless mode and
your modular proposal drafts are archived, unchanged, at tag
`archive/headless-in-keepresso-2026-11-02`, together with the uncommitted
drafts, which were committed first as `53d8240`. New work is on branch
`sh/foundation`, created from `upstream/main` `7ea73a6`. Nothing has been
pushed.

Read [README.md](README.md) first, then the other docs in the order it lists.

## What changed from your proposal

The goals of your proposal carry over: shared modules, typed observations with
availability, pure evaluation, separate SH service identity, a removal
transaction, and evidence-based acceptance. These parts are different:

1. **Scope.** Only the modules SH needs are built now. `KeepressoContracts`,
   `KeepressoRuntime`, `ProductAdapters` and Keepresso's adoption layer are
   deferred to Stages E and G.
2. **Build alongside instead of moving files.** Keepresso stays byte-identical
   to upstream through Stage D (invariant I1). The shared code is seeded from
   Keepresso's code with recorded provenance (I3, I4).
3. **PowerControl is narrowed to keep-awake holds.** AWDL and KeyboardLock stay
   in Keepresso.
4. **No SharedSupport module** for now (T6).
5. **Contracts do not depend on RuleModel.** Products map shared types into
   their own versioned DTOs (T3).
6. **Boundaries are enforced by SwiftPM target dependencies** rather than
   `check_boundaries.py` (T2).
7. **The docs are consolidated** into `docs/sleepless-hollow/`. `PRODUCT.md` and
   `VALIDATION.md` are carried forward from your drafts with edits.

## What you are asked to do

1. Read all seven docs. Check their factual claims against the code at
   `upstream/main` and at the archive tag: file names, line hints, semantics
   described as Keepresso's, and the defects F1 to F6.
2. Write `docs/sleepless-hollow/CODEX-REVIEW.md` containing:
   - for each technical decision T1 to T10: agree, or disagree with your reason
     and an alternative;
   - factual errors in any doc, with file and line evidence;
   - missing items: sources, tests, defects, risks or stages;
   - proposed changes to stage order or exit criteria;
   - anything in your archived drafts that should come back, and why.
3. Do not change the other docs or write code yet. jbrest settles the review,
   then the docs are updated (by you or Claude Code, as jbrest chooses), and
   Stage 0 closes.
4. After Stage 0 closes, you implement Stages A to D. Keep NOTES.md and the
   "Ported at" table in SOURCE-INVENTORY.md current as you go.

## Working rules

The repo's `.clinerules` and `CLAUDE.md` apply:
- Before multi-step work, state a short plan and wait for approval.
- Never read a whole file over 300 lines; search, then read ranges.
- One goal per task.
- Stop and explain after two failed approaches.
- Ask before long-running or background commands.
- Keep NOTES.md current after each milestone.
- Never use em dashes in prose, comments, commit messages or UI copy.
- Keep `ENABLE_APP_SANDBOX: false`.
- Never commit `Keepresso.xcodeproj`.

Commits should be tidy because the fork is public. Do not push without jbrest's
approval, and never contact upstream.
