# Sleepless Hollow planning docs

Date: 2 November 2026. Branch: `sh/foundation`, created from `upstream/main`
(`7ea73a6`). Owner: jbrest. Prepared with Claude Code and Codex. At the end-of-Stage-A review checkpoint
(see [CODEX-BRIEF.md](CODEX-BRIEF.md) and [NOTES.md](../../NOTES.md)).

Sleepless Hollow (SH) is a standalone macOS app plus root background service
that keeps a Mac awake on conditions, including when no one is logged in. It is
built in this fork of Keepresso on a set of shared modules carved out of
Keepresso's code. Keepresso adopts the rule and observation modules as they are
built, through wrappers and a two-state adapter, with no UI changes. Its
privileged helper is left alone until a later, separately approved stage.

## Reading order

1. [ARCHITECTURE.md](ARCHITECTURE.md): target modules, dependency rules and
   design principles.
2. [MIGRATION-PLAN.md](MIGRATION-PLAN.md): stages, invariants and exit
   criteria.
3. [SOURCE-INVENTORY.md](SOURCE-INVENTORY.md): what each module is built from,
   known defects to fix on the way, and what is deliberately left behind.
4. [DECISIONS.md](DECISIONS.md): decided and open questions.
5. [PRODUCT.md](PRODUCT.md): SH behavior and UI.
6. [VALIDATION.md](VALIDATION.md): acceptance checks per stage.
7. [CODEX-BRIEF.md](CODEX-BRIEF.md): instructions for the review and handoff.

Running status (done, next, open questions) is in [NOTES.md](../../NOTES.md) at
the repo root.

## Which file to update

| When this happens | Update |
| --- | --- |
| A module boundary or principle changes | ARCHITECTURE.md, plus a DECISIONS.md entry |
| A stage starts, finishes or changes scope | MIGRATION-PLAN.md and NOTES.md |
| Code is ported or written from a source | SOURCE-INVENTORY.md (provenance) |
| A question is settled | DECISIONS.md, then the doc it affects |
| Product behavior changes | PRODUCT.md |
| Any milestone | NOTES.md |

## The archive

Everything from the earlier approach (Headless mode built inside Keepresso,
helper protocol 16, Codex's modular proposal drafts, the Claude and Codex review
exchange) is preserved at the annotated tag
`archive/headless-in-keepresso-2026-11-02` (commit `53d8240`) and on the local
branch `codex/headless-lifecycle`. Neither has been pushed by this change.

Read an archived file without switching branches:

```sh
git show archive/headless-in-keepresso-2026-11-02:docs/HEADLESS-MODE-SCOPE.md
git show archive/headless-in-keepresso-2026-11-02:Sources/KeepressoCore/HeadlessSupervisor.swift
```

Archived docs that remain useful as history: `docs/HEADLESS-MODE-SCOPE.md`
(requirements and installed-test log), `NOTES.md`,
`docs/MODULAR-INTERFACES.md`, `docs/SOURCE-MIGRATION-MAP.md` and
`docs/archive/headless-review-2026-11-01/`. The current docs supersede them.
