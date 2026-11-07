# Plan: Accept a valid module-self colon form

From `intent.md` (2026-11-06). Status: accepted.

This is the `rubocop-eirvandelden` part of the sticker-app plan `docs/changes/fix-rbs-inline-lint-and-steep-offenses/plan.md` (sticker-app commit `c5558a7`). That plan was accepted on 2026-11-07 after one Codex critique round, with all 3 findings fixed. This file copies the parts for this repository.

## Context

- `rubocop-rbs_inline` 2.0.0 has no config option on `InvalidTypes` or `KeywordSeparator`. A config-only fix cannot accept the colon form and keep both cops' other checks.
- rbs-inline 0.14 parses `# @rbs module-self: Foo` as `RBS::Inline::AST::Annotations::ModuleSelf` with empty `self_types`, so upstream `InvalidTypes#invalid_annotation?` returns true. For `#: (Integer -> void` it yields a `SyntaxErrorAssertion`, which stays an offense.
- Upstream `KeywordSeparator#on_investigation_end` skips a comment when its private `valid_method_annotation?(comment)` returns true. That is the one hook the subclass needs.
- RBS 4.2 (`RBS::InlineParser`, used by Steep 2.1 with `inline: true`) requires the colon after `module-self`.
- appkit writes the bare form `# @rbs module-self ::ActiveRecord::Base`. That form must stay clean.
- The `db/queue_migrate` exclusion is already on `main` (`d91402e`). Its glob `**/db/*_migrate/**/*` covers `db/cache_migrate` too.

## Design decisions

- Keep both cops in the `Style/RbsInline` namespace, so they inherit the department config (`Mode: opt_out`, the `test/` and `spec/` excludes).
- Wrap `KeywordSeparator` instead of switching it off, so `skip:`, `override:`, `inherits:` and the rest stay flagged.
- Validate the type after the colon with `RBS::Parser.parse_type`. A colon form with a broken type is not accepted; both cops then report it as upstream does.
- Subclass and call `super`, with no prepend. The overrides couple to upstream's private `invalid_annotation?` and `valid_method_annotation?`. If upstream renames either, the colon form is flagged again: a loud failure, caught by the colon-form test. The `~> 2.0` constraint limits the exposure.
- Keep the gem version at 1.0.0, with an Unreleased CHANGELOG entry. Consumers pin by git revision.

## Files that change

- `lib/rubocop/cop/style/rbs_inline/module_self_colon_form.rb` — new: the shared mixin.
- `lib/rubocop/cop/style/rbs_inline/invalid_types_allowing_colon.rb` — new: the `InvalidTypes` subclass.
- `lib/rubocop/cop/style/rbs_inline/keyword_separator_allowing_colon.rb` — new: the `KeywordSeparator` subclass.
- `config/default.yml` — `require:` both cop files, switch the two upstream cops off and both subclasses on, with a comment on Steep's colon.
- `rubocop-eirvandelden.gemspec` — ship `lib/**/*.rb`.
- `test/shared_configuration_test.rb` — the tests under Proof, `db/cache_migrate` in the Solid migration test, and the updated rule lists.
- `CHANGELOG.md`, `README.md`, `AGENTS.md` — document the two replaced cops and that the gem now ships Ruby under `lib/`.

## Proof

- `# @rbs module-self: Foo` gets no offense → `test_a_module_self_annotation_with_a_colon_passes_lint`.
- `#: (Integer -> void` still gets an invalid-types offense → `test_a_broken_signature_fails_lint_as_an_invalid_type`.
- A method without a signature in a Solid migration folder gets no offense → the Solid migration test (with `db/cache_migrate`), and `test_a_rails_project_still_demands_a_signature_in_app`.
- A colon form with a broken type gets an offense → `test_a_module_self_annotation_with_a_colon_and_a_broken_type_fails_lint`.
- `# @rbs skip:` still gets a keyword-separator offense → `test_a_colon_after_skip_still_fails_lint`.
- The bare form gets no offense → `test_a_module_self_annotation_without_a_colon_passes_lint`.
- The upstream cops stay off and the subclasses stay on → the two rule-list tests.
- The gem ships its cop files → `test_the_gem_ships_the_cops_it_requires`.
- appkit stays clean with this branch → check: lint a scratch copy of appkit against this branch's config.

## Verification so far

- `bundle exec rake test`: 47 runs, 0 failures. `bundle exec rubocop`: no offenses.
- sticker-app against this branch: 136 files, no offenses.
- appkit against this branch, with its own todo and settings: 110 files, no offenses.
