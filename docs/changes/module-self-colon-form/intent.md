# Intent: Accept a valid module-self colon form

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no.

This is the `rubocop-eirvandelden` part of the sticker-app change `fix-rbs-inline-lint-and-steep-offenses`. Etienne accepted that intent on 2026-11-06. It covers this repository, appkit and sticker-app. This file restates the part for this repository.

## Problem

`Style/RbsInline/InvalidTypes` and `Style/RbsInline/KeywordSeparator` (`rubocop-rbs_inline` 2.0.0) reject `# @rbs module-self: X`. They follow the `rbs-inline` gem's syntax, which wants `module-self X`. Steep 2.1 checks with `inline: true`, which uses RBS 4's own inline parser, and that parser requires the colon. A repository that type-checks with Steep cannot get a clean lint run: sticker-app reports 14 offenses in 6 files, and obeying the cop gives 28 Steep errors.

## Proposed outcome

A valid `# @rbs module-self: X` passes lint. Every other invalid inline RBS annotation is still flagged.

## Affected users and systems

Every personal repository that inherits `rubocop-eirvandelden`. sticker-app picks the change up first.

## Constraints

- Steep is the authority on inline RBS syntax: the colon form stays valid.
- No linter disable comments.

## In scope

- Accept `# @rbs module-self: X` when `X` is a valid type.
- Keep the bare form `# @rbs module-self X` clean, since appkit writes it.
- Exclude every Solid `db/*_migrate/` folder from `MissingTypeAnnotation`; the test also covers `db/cache_migrate`.

## Out of scope

- Upstream changes to `rubocop-rbs_inline`.
- The dotfiles copy `~/Developer/dotfiles/rubocop/.rubocop.yml`, which cannot load the gem's cops.
- Bumping this gem in its consumers, apart from sticker-app.

## Acceptance criteria

- A file with `# @rbs module-self: Foo` gets no offense.
- A file with a broken type such as `#: (Integer -> void` still gets an invalid-types offense.
- A method without a signature in `db/queue_migrate/` gets no offense, and the same method in `app/models/` still gets `MissingTypeAnnotation`.

## Decisions

- Fix the cop-versus-Steep conflict in this gem, not in each app — the conflict is not specific to one app.
- Leave the dotfiles copy alone — it cannot load the new cops, and keeping it out keeps this change in scope.

## Open questions

None.
