# Intent: Update all dependencies, including Ruby

Author: Etienne van Delden. Status: accepted (2026-10-21).
Type: chore. Delivery: autonomous. Codex review: no.

## Problem

The development Ruby (4.0.5), the locked gems (`rubocop-capybara` 3.0.0, `uri` 1.1.1) and the GitHub Actions in CI are behind their latest releases.

## Proposed outcome

The repository runs on the latest installed Ruby 4.0 patch, the latest gem versions and the latest GitHub Actions. Lint and tests stay green.

## Affected users and systems

The gem's maintainer and CI. Consumers see the new minimum Ruby, 4.0, on their next `bundle update rubocop-eirvandelden`.

## Constraints

- No gem is added or removed. Only versions move.
- `.ruby-version` moves to 4.0.7, which `rv` already has installed. Nothing is installed.
- Approved for this change only: editing `.github/workflows/ci.yml` (playbook rule 13).
- Update gems with `bundle update <gem>`, never a bare `bundle update` (rule 11). Use `bi` to install.
- Raising `required_ruby_version` changes the gem's contract, so it needs a CHANGELOG entry.

## In scope

- `.ruby-version`: 4.0.5 to 4.0.7.
- `rubocop-eirvandelden.gemspec`: `required_ruby_version` from `>= 3.4` to `>= 4.0`.
- `Gemfile.lock`: every gem to its latest version, including `rubocop-capybara` and `uri`, and the Ruby version it records.
- `.github/workflows/ci.yml`: bump the pinned action versions.
- `CHANGELOG.md` and any README line that names the Ruby minimum.
- Fix any cop or test breakage the new versions cause, in the config or tests, never by disabling a cop to hide it.

## Out of scope

- Adding or removing dependencies.
- Changing `dependabot.yml`.
- Moving to a Ruby major or minor beyond 4.0.x.
- Any rule change in `config/`, except what a gem update forces.

## Acceptance criteria

- `ruby -v` in the repository prints 4.0.7.
- `bundle outdated` lists nothing.
- `bundle exec rake test` passes.
- `bundle exec rubocop` passes.
- A consumer on Ruby 3.4 is refused by the gemspec; one on 4.0 installs it.
- The CHANGELOG records the raised minimum Ruby.
- The CI workflow uses the latest released version of each action it pins.

## Decisions

- Ruby goes to 4.0.7 — latest installed 4.0.x patch, no install needed.
- Raise `required_ruby_version` to `>= 4.0` — Etienne chose it over keeping `>= 3.4`; no reason given.
- Bump GitHub Actions in `ci.yml` — Etienne approved the workflow edit; no reason given.
- Autonomous delivery without Codex review — Etienne chose it.
- "`bundle outdated` lists nothing" is proved with `bundle outdated --strict` — prism 2 is capped by rubocop-ast and minitest; Etienne chose --strict over blocking the change.
- `ci.yml` stays unchanged — checkout@v7.0.1 is the latest release and setup-rv@main is newer than its only tag; Etienne accepted that.

## Open questions

None.
