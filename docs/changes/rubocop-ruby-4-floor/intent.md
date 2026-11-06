# Intent: Require a RuboCop that knows Ruby 4.0

Author: Etienne van Delden. Status: accepted (2026-11-06). Type: bugfix. Delivery: autonomous. Codex review: no.

## Problem

The gem requires Ruby 4.0 but asks for `rubocop` with no version floor. A project that resolves its gems fresh can get a RuboCop too old to know Ruby 4.0. Appkit CI (run 40345668764 on appkit PR #24) drops its lockfile, resolves prism 2.0.0, and falls back to RuboCop 1.74. Lint then fails with "unknown Ruby version 4.0 in TargetRubyVersion parameter".

RuboCop 1.82.0 (2025-12-17) is the first release that accepts `TargetRubyVersion 4.0` (changelog entry #14644, "experimental"). Verified in source: `KNOWN_RUBIES` in v1.81.7 ends at 3.5; in v1.82.0 it holds 4.0. This gem's lockfile holds RuboCop 1.92.1, the version its CI tests.

## Proposed outcome

A fresh resolve of any project that uses this gem picks RuboCop 1.92 or newer, a version that knows Ruby 4.0 and that this gem's CI tests. When no such RuboCop fits next to the project's other gems, Bundler refuses to resolve. It does not fall back to an old RuboCop.

## Affected users and systems

- Every personal project that inherits this gem, especially projects whose CI resolves without a lockfile (appkit).
- Projects locked to RuboCop 1.82–1.91 must update RuboCop when they update this gem.
- The gem's own lockfile already holds RuboCop 1.92.1, so this repository's CI does not change.

## Constraints

- Etienne approved this dependency constraint change on 2026-11-06 (playbook rule 11). No other permission is needed: no new gems, system tools, migrations or deploy files.
- Constraint style follows the `dependencies` skill: `~> major.minor`.

## In scope

- The constraint `~> 1.92` on `rubocop` in `rubocop-eirvandelden.gemspec`.
- A test that asserts the constraint.
- A line in the `1.0.0` section of `CHANGELOG.md` (no release is tagged yet, as with the Ruby 4.0 minimum).

## Out of scope

- Floors on the other bundled cop gems.
- The appkit fix in `rakelib/signatures.rake:12`; it stays in appkit PR #24.
- The gem version number.

## Acceptance criteria

- A project cannot resolve this gem next to RuboCop 1.74, nor next to 1.91.
- RuboCop 1.92.0, the locked 1.92.1 and any later 1.x satisfy the gemspec; RuboCop 2.0 does not.
- The changelog tells consumers that the gem now needs RuboCop 1.92 or newer.

## Decisions

- Require `~> 1.92`, not the minimum `~> 1.82` — this is Etienne's own software, so its projects can upgrade to newer versions of dependencies.
- Deliver autonomously, without a Codex review — this is Etienne's own software.

## Open questions

None.
