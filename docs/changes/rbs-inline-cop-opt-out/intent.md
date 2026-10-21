# Intent: Demand inline RBS signatures in every file of a personal project

Author: Etienne van Delden. Status: accepted (2026-10-21). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

Personal Ruby code must carry inline RBS signatures, as the `ruby-style` skill says. The shared config checks inline RBS annotations only in files that start with `# rbs_inline: enabled`. No consuming project has that comment, so no annotation is ever checked: `appkit` has 33 annotated files, and a malformed annotation in any of them passes lint. Lint also never demands a signature, so a public method without one passes. The dotfiles fallback `~/.rubocop.yml` checks every file, but it also only validates annotations and never demands them.

## Proposed outcome

A project that inherits `config/default.yml` gets every file checked, with no magic comment. Existing annotations are validated, and public methods, `attr_*` declarations, `Data.define` attributes and `Struct.new` attributes must carry a type. A file skips all inline RBS checks only with `# rbs_inline: disabled`. The dotfiles fallback `~/.rubocop.yml` demands the same rules, so a loose Ruby file outside any project is held to the same standard.

## Affected users and systems

- Every personal Ruby project that inherits `rubocop-eirvandelden` (ambx, appkit, cityofbrass, clocky, ddicompendium, journal_administration, happiness, my-rails-template, mvpa.css, sticker-app), after `bundle update rubocop-eirvandelden`. Each one fails lint until its public methods are annotated.
- The gem's `config/default.yml`, `config/rails.yml`, gemspec version, test, README and CHANGELOG.
- The dotfiles repository: `rubocop/.rubocop.yml`, the source of the `~/.rubocop.yml` symlink, and the `ruby-style` skill at `agents/.agents/skills/ruby-style/SKILL.md`.

## Constraints

- Layering rules in CLAUDE.md stay: `default.yml` is the base layer and no layer inherits from another. Rails-only exclusions live in `rails.yml`.
- No new dependency. No system tool, migration or deploy file is touched.
- Approved: editing the dotfiles source files `rubocop/.rubocop.yml` and `agents/.agents/skills/ruby-style/SKILL.md` on their own branch and pull request in the dotfiles repository. Never edit the symlink and never run `stow` (playbook rule 12).
- Both repositories are personal (`eirvandelden`), so autonomous delivery applies to both pull requests.

## In scope

- Check every file: switch `Style/RbsInline` to `Mode: opt_out`.
- Switch on the demanding cops `MissingTypeAnnotation` (style `method_type_signature`, public methods and `attr_*` only), `MissingDataClassAnnotation` and `MissingStructClassAnnotation`.
- Switch on the validating cops still off: `DataClassCommentAlignment`, `DataDefineWithBlock`, `StructClassCommentAlignment`, `StructNewWithBlock`, `RedundantInstanceVariableAnnotation`.
- Keep `RequireRbsInlineComment` on, so a leftover `# rbs_inline: enabled` is flagged and autocorrect removes it.
- Keep the plugin's exclusion of `test/**/*` and `spec/**/*` from all inline RBS checks.
- In `config/rails.yml`, exclude `db/migrate` from `MissingTypeAnnotation`.
- Bump the gem to `1.0.0`. The CHANGELOG names the breaking change and the `# rbs_inline: disabled` escape.
- Update the README and the gem's test to match.
- Give the dotfiles fallback `~/.rubocop.yml` the same mode, cops, settings and migration exclusion.
- Change the `ruby-style` skill in dotfiles: personal methods carry a `#:` signature, not `# @rbs` lines.

## Out of scope

- Work projects. They do not inherit this gem. Keeping RBS out of work files is a separate concern.
- Annotating or fixing code in consuming projects such as `appkit`.
- `UntypedInstanceVariable`: instance variables need no type.
- RBS type checking (Steep, `rbs validate`) and `sig/` generation.
- YARD, RSpec and Capybara settings.

## Acceptance criteria

- A file with no magic comment and the annotation `# @rbs name: Array[String` fails lint under `default.yml`.
- A public method `def greet(name)` with no annotation fails lint. With `#: (String) -> String` directly above it, it passes.
- A private method with no annotation passes lint.
- `attr_reader :name` in public scope fails lint without a trailing `#: String`, and passes with it.
- `Point = Data.define(:x, :y)` fails lint until each attribute has a `#:` type. `Struct.new` behaves the same.
- A file that starts with `# rbs_inline: disabled` passes lint, however it is annotated.
- A file that carries `# rbs_inline: enabled` fails lint with "Remove `# rbs_inline:` magic comment.", and autocorrect removes the comment.
- A method marked `# @rbs skip` passes lint without a signature.
- An unannotated public method in `test/` or `spec/` passes lint.
- In a project on `default.yml` and `rails.yml`, a migration's `def change` passes without a signature. A controller's public action without a signature fails.
- The gem reports version `1.0.0`, and the CHANGELOG states the break and the `# rbs_inline: disabled` escape.
- A loose Ruby file outside any project, linted by the fallback `~/.rubocop.yml`, fails on an unannotated public method and passes once it is annotated.
- The `ruby-style` skill tells an agent to write `#: (String) -> String` above a personal method, and no longer offers `# @rbs` lines as a method signature.
- The gem's test suite and its own RuboCop run are green.

## Flagged concerns

- The `ruby-style` skill allows `#:` or `# @rbs` method signatures, but no plugin style accepts both. Chosen side: lint demands `#:` only, and the skill changes to match in this delivery.

## Decisions

- Check every file (`opt_out`); `# rbs_inline: disabled` is the only way out — personal files should use RBS inline.
- Work files should not use RBS inline, but that is out of scope here — work projects do not inherit this gem.
- Type is feature — it changes what lint reports in every consuming project.
- Demand annotations, not only validate them — lint must enforce the `ruby-style` rule that personal methods carry signatures.
- Demand `MissingTypeAnnotation`, `MissingDataClassAnnotation` and `MissingStructClassAnnotation`, not `UntypedInstanceVariable` — low noise: instance variables add noise without much safety.
- Methods use `#:` signatures only (`method_type_signature`), and this delivery fixes the `ruby-style` skill to match — one signature style reads consistently.
- Only public methods and `attr_*` must carry a signature — low noise: private helpers add noise without much safety.
- Switch on all five remaining validating cops — they fit the Data and Struct cops.
- Flag and remove a leftover `# rbs_inline: enabled` — the comment is redundant in `opt_out` mode, and no consuming project carries it.
- Keep the plugin's exclusion of tests and specs — plugin default.
- Exclude migrations from the demand, not controllers or mailers — migrations are generated, run once and never called from code.
- Bump to `1.0.0` — a clear signal that lint now breaks.
- Change the dotfiles fallback in this delivery — the gem and the fallback must demand the same rules, and shipping them together avoids drift.
- Autonomous delivery, no Codex review — no reason given.

## Open questions

None.
