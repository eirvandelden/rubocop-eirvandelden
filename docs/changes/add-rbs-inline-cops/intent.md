# Intent: Check inline RBS annotations in the shared RuboCop config

Author: Etienne van Delden. Status: accepted. Type: feature. Delivery: autonomous

## Problem

Etienne's dotfiles now prefer inline RBS (`rbs-inline`) over YARD for documenting types. The shared RuboCop config still lints YARD comments and does not check inline RBS annotations at all. A project can ship a malformed `#:` or `# @rbs` annotation and lint stays green.

## Proposed outcome

A project that inherits `config/default.yml` gets its inline RBS annotations checked. The YARD cops stay available but no longer run unless a project opts in.

## Affected users and systems

- Every personal Ruby project that inherits `rubocop-eirvandelden`. They pick the change up after `bundle update rubocop-eirvandelden`.
- The gem's own config files, gemspec, test, README, CHANGELOG and AGENTS.md.

## Constraints

- Approved dependency (playbook rule 11): `rubocop-rbs_inline`, as a runtime dependency of the gem.
- The gem keeps its rule that a consuming project adds nothing to its own Gemfile.
- Layering rules in CLAUDE.md stay: `default.yml` is the base layer and no layer inherits from another.
- Checks run in opt-in mode. Only files with `# rbs_inline: enabled` are checked, and a file without it is not flagged (`AllowMissingComment: true`).

## In scope

- Add `rubocop-rbs_inline` to the gemspec and to the plugins in `config/default.yml`.
- Configure its `Style/RbsInline` cops for opt-in mode, with no demand for the magic comment.
- Keep `rubocop-yard` as a dependency, but disable the YARD department by default so a project can opt back in.
- Extend `test/shared_configuration_test.rb` to assert the RBS cops are active and the YARD department is off.
- Update README, CHANGELOG and the AGENTS.md cop-gem list.

## Out of scope

- Removing `rubocop-yard` or the YARD cop settings.
- Requiring annotations in files that have not opted in.
- Adding RBS type checking (Steep, `rbs validate`) or `sig/` generation.
- Changes to consuming projects or to the dotfiles.
- Rails, RSpec and Capybara layers.

## Acceptance criteria

- A file with `# rbs_inline: enabled` and a malformed annotation fails lint under `default.yml`.
- A file with `# rbs_inline: enabled` and a valid annotation passes lint.
- A file without `# rbs_inline: enabled` passes lint, however it is annotated.
- A YARD comment with a wrong tag type no longer fails lint under `default.yml` alone.
- A project that sets `YARD: Enabled: true` gets the YARD cops back.
- The gem's test suite and its own RuboCop run are green.

## Open questions

None.
