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
   `KeepressoRuntime` and `ProductAdapters` are deferred to Stages E and G.
2. **Two tracks (decision P7).**
   - **Rules and observations move out of `KeepressoCore` one condition at a
     time.** Each Keepresso trigger becomes a wrapper with its own two-state
     adapter. Keepresso's existing tests must pass unchanged after every move,
     and the UI is never edited.
   - **The privileged helper code is not moved.** SH's PowerControl and
     ServiceSupport are built fresh, seeded from it with recorded provenance.
     Keepresso's helper adopts them only in Stage E.
   - An earlier version of this plan built everything alongside Keepresso. It
     was revised the same day, and DECISIONS.md P3 and P7 record the change.
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
   - for each technical decision T1 to T10 and for P7's two-track split: agree,
     or disagree with your reason and an alternative;
   - whether the Stage A order and the per-condition adapter approach are
     workable, and anything in `KeepressoCore` that makes a clean wrapper hard
     (for example, cross-file private access, or triggers that read state in
     `tick`);
   - factual errors in any doc, with file and line evidence;
   - missing items: sources, tests, defects, risks or stages;
   - proposed changes to stage order or exit criteria;
   - anything in your archived drafts that should come back, and why.
3. Do not change the other docs or write code yet. jbrest settles the review,
   then the docs are updated (by you or Claude Code, as jbrest chooses), and
   Stage 0 closes.
4. After Stage 0 closes, you implement Stages A to D. Keep NOTES.md, the
   "Done" table in SOURCE-INVENTORY.md and the O11 table in DECISIONS.md
   current as you go.
5. Stop at each review checkpoint listed in NOTES.md, and tell jbrest that a
   Claude Code review is due before continuing.
6. Review every upstream file you move, wrap or seed from for correctness bugs,
   following "Reviewing touched upstream code" in MIGRATION-PLAN.md.
   - Never fix a suspected upstream bug inside a move. Preserve the behavior
     and record it in the "Upstream fix candidates" table in NOTES.md.
   - Confirm each one with a failing test on a separate `upstream-fix/` branch
     from `upstream/main`.
   - jbrest decides which fixes are offered upstream, as small standalone PRs
     submitted as a goodwill gesture before any reorganization offer.
   - Low-value findings are recorded but not proposed.
   - In your review of these docs, say whether this procedure is workable and
     what you would change.

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
