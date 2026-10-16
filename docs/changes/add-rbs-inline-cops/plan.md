# Plan: Check inline RBS annotations in the shared RuboCop config

From `intent.md` (2026-10-16). Status: accepted.

## Context

`rubocop-eirvandelden` is a RuboCop configuration gem. `config/default.yml` inherits `rubocop-rails-omakase`, loads the bundled cop plugins, and turns chosen cops back on. `test/shared_configuration_test.rb` runs `bundle exec rubocop --show-cops` against the config files and asserts each setting. This change adds `rubocop-rbs_inline` (version 2.0.0 at the time of writing, Ruby >= 3.3, depends on `rbs-inline`, `lint_roller` and `rubocop`) and switches the YARD department off by default.

Facts this plan relies on, all checked against the installed gems:

- Omakase sets `Style: Enabled: false` and `Layout/LeadingCommentSpace: Enabled: true`. Omakase does not set `DisabledByDefault`.
- `rubocop-rbs_inline` puts every cop under the nested department `Style/RbsInline`. Its own defaults are `Enabled: true`, but omakase's `Style` switch-off disables them all. Each cop must be switched on by name, the way this gem already switches on Performance cops.
- `rubocop-rbs_inline`'s `Style/RbsInline` department defaults to `Mode: opt_in` and excludes `spec/**/*` and `test/**/*`. In opt-in mode, every checking cop skips a file without `# rbs_inline: enabled`.
- `Style/RbsInline/RequireRbsInlineComment` defaults to `AllowMissingComment: false`.
- With `Layout/LeadingCommentSpace` as it is now, `def greet(name) #: String` fails with "Missing space after #." The cop has an `AllowRBSInlineAnnotation` option (default `false`).
- RuboCop keeps a cop on when the same file both disables its department and sets `Enabled: true` on the cop (`ConfigLoaderResolver#override_department_setting_for_cops` marks it `override_department`). Verified: `config/default.yml` plus `YARD: Enabled: false` still reports `YARD/TagTypeSyntax`. With the six `YARD/*: Enabled: true` entries removed it reports nothing. A config that inherits that and sets `YARD: Enabled: true` reports `YARD/TagTypeSyntax` again, with `rubocop-yard`'s own defaults.
- `rubocop --stdin lib/example.rb -c <config>` lints source from standard input as if it lived at that path. A path under `lib/` avoids `Style/RbsInline`'s `test/**/*` exclude.

## Design decisions

- **Switch on the validating cops only, by name.** `config/default.yml` enables `InvalidComment`, `InvalidTypes`, `KeywordSeparator`, `ParametersSeparator`, `UnmatchedAnnotations`, `RedundantTypeAnnotation`, `MethodCommentSpacing`, `VariableCommentSpacing`, `EmbeddedRbsSpacing` and `RedundantAnnotationWithSkip`. This is the same set the dotfiles' fallback `~/.rubocop.yml` already enables. These cops check annotations that exist; none of them demands an annotation. The cops that demand annotations (`MissingTypeAnnotation`, `MissingDataClassAnnotation`, `MissingStructClassAnnotation`, `UntypedInstanceVariable`) and the `Data.define`/`Struct.new` shape cops (`DataDefineWithBlock`, `StructNewWithBlock`, `DataClassCommentAlignment`, `StructClassCommentAlignment`) stay off. Reason: `intent.md` asks for malformed annotations to fail, not for missing ones. `MissingTypeAnnotation`'s default `doc_style` would also reject the `#: (Board) -> void` style the dotfiles' `rails-architecture` skill uses. Whether to demand annotations in opted-in files is a separate decision for Etienne.
- **Name `Mode: opt_in` explicitly** under `Style/RbsInline`, although it is the plugin's default. A plugin release that changes the default then cannot switch every file on. Keep the plugin's `test/**/*`/`spec/**/*` exclude by not setting `Exclude` there.
- **`RequireRbsInlineComment` on, with `AllowMissingComment: true`.** `intent.md` names this setting. In opt-in mode the cop then never reports, but naming it records the choice and keeps it safe if `Mode` changes.
- **`Layout/LeadingCommentSpace: AllowRBSInlineAnnotation: true`.** Without it a valid `#:` annotation fails lint, in every file, opted in or not. Acceptance criteria 2 and 3 need it.
- **Turn YARD off with `YARD: Enabled: false` and remove the six `YARD/*: Enabled: true` entries.** The entries must go: RuboCop otherwise keeps those cops on despite the department switch (see Context). They only restate `rubocop-yard`'s defaults, which also enable exactly those six cops, so a project that sets `YARD: Enabled: true` gets the same six cops with the same settings. `intent.md` lists "removing the YARD cop settings" as out of scope. This plan reads that as "keep YARD available with its current behaviour", which this keeps. Removing the entries is the only way to meet the accepted criteria "no longer fails under `default.yml` alone" and "`YARD: Enabled: true` gets the YARD cops back" together. The report flags this reading for Etienne to confirm. A comment above the switch says how to opt back in.
- **`rubocop-yard` stays** in the gemspec and in the `plugins` list, so the opt-in works with no Gemfile change.
- **Gemspec order.** Add `spec.add_dependency "rubocop-rbs_inline"` between `rubocop-rails` and `rubocop-rspec`, alphabetical like its neighbours. No version constraint, matching every other dependency in the file.
- **Behaviour tests lint real source.** A new private helper `lint(source, configuration = "config/default.yml")` pipes source into `bundle exec rubocop --stdin lib/example.rb -c <configuration> --format simple` and returns output and status. Ruby sources live in heredoc constants in the test class. Each source is clean under every other cop in `default.yml`, so a pass means no offense at all.
- **No version bump.** `CHANGELOG.md` gets an `## Unreleased` section. Releasing is outside `intent.md`.

## Integration points

- `rubocop-rbs_inline` loads through RuboCop's plugin system (`lint_roller`). It requires `rbs/inline` at load, which pulls `rbs-inline` and `rbs ~> 4.0` into `Gemfile.lock`. `prism` is already locked.
- Consuming projects get the change on `bundle update rubocop-eirvandelden`. A project that relies on YARD lint must add `YARD: Enabled: true` to its own `.rubocop.yml`.
- The gem's own `.rubocop.yml` inherits `config/default.yml`, so CI's `bundle exec rubocop` now runs the RBS cops on this repo too. No file here has the magic comment, so they report nothing.

## Files that change

- `rubocop-eirvandelden.gemspec` — add `spec.add_dependency "rubocop-rbs_inline"`.
- `Gemfile.lock` — regenerated by `bi` for the new dependency and its own dependencies.
- `config/default.yml` — add `rubocop-rbs_inline` to `plugins` (alphabetical, after `rubocop-rails`); add `Style/RbsInline: Mode: opt_in`; enable the ten validating cops by name; add `Style/RbsInline/RequireRbsInlineComment` with `Enabled: true` and `AllowMissingComment: true`; add `Layout/LeadingCommentSpace: AllowRBSInlineAnnotation: true`; replace the six `YARD/*` entries with `YARD: Enabled: false` and a comment that says how to opt back in. Each new block gets a one-line "why" comment in the file's existing style.
- `test/fixtures/project_using_yard.yml` — new. `inherit_from: ../../config/default.yml`, then `YARD: Enabled: true`, with a short header comment like the other fixtures.
- `test/shared_configuration_test.rb` — new acceptance and settings tests (see Proof); remove the six YARD cops from `RULES_WE_TURN_ON`; add the `lint` helper. `CORE_DEPARTMENTS` keeps `YARD`: the cops are still offered, only off.
- `README.md` — "What you get": list the inline RBS checks; say they run only in files with `# rbs_inline: enabled`; say YARD is bundled but off and show the `YARD: Enabled: true` opt-in.
- `CHANGELOG.md` — `## Unreleased` entry: inline RBS checks added, YARD off by default, how to opt back in.
- `AGENTS.md` — add `rubocop-rbs_inline` to the bundled cop-gem list in "What this is". (`CLAUDE.md` is a symlink to it; do not touch the symlink.)

## Order of work

1. Write `test_a_malformed_inline_rbs_annotation_fails_lint_in_a_file_that_opts_in` and the `lint` helper. Run `bundle exec ruby -Itest test/shared_configuration_test.rb -n test_a_malformed_inline_rbs_annotation_fails_lint_in_a_file_that_opts_in`. Watch it fail: the test asserts the output names a `Style/RbsInline/` cop, and no such cop exists yet.
2. Add `rubocop-rbs_inline` to the gemspec. Run `bi` (never `bundle install`). Confirm `Gemfile.lock` gained `rubocop-rbs_inline`, `rbs-inline` and their dependencies, and nothing else moved.
3. Add the plugin, `Style/RbsInline: Mode: opt_in` and the ten validating cops to `config/default.yml`. Re-run step 1's test; it passes.
4. Write the settings test for the ten validating cops; it passes. Write the `AllowMissingComment` test; watch it fail; add `RequireRbsInlineComment`; it passes.
5. Write the valid-annotation acceptance test; watch it fail on `Layout/LeadingCommentSpace`; add `AllowRBSInlineAnnotation: true`; it passes. Add the `AllowRBSInlineAnnotation` settings test.
6. Write the not-opted-in acceptance test; it should pass already. Confirm it fails if `Mode` is temporarily set to `opt_out`, then restore `opt_in`.
7. Write the YARD acceptance test for `default.yml`; watch it fail (`YARD/TagTypeSyntax` reports today). Add `YARD: Enabled: false` and remove the six `YARD/*` entries; remove those six from `RULES_WE_TURN_ON`. It passes.
8. Add `test/fixtures/project_using_yard.yml`. Write the YARD opt-in acceptance test and `test_yard_rules_stay_off_until_a_project_asks_for_them`; both pass.
9. Update `README.md`, `CHANGELOG.md` and `AGENTS.md`.
10. Run `bundle exec rake test` and `bundle exec rubocop`. Both green. Re-read the full diff.

## Risks

- **A heredoc source trips an unrelated cop**, so a "passes lint" test fails for the wrong reason. Keep sources minimal (no frozen string literal comment, short lines, plain method bodies). Every opted-in source puts a blank line after `# rbs_inline: enabled`: RuboCop treats it as a magic comment, and `Layout/EmptyLineAfterMagicComment` fails it otherwise (verified). The pass tests assert on the full output, so the failure message names the cop.
- **The malformed source does not trip the intended cop.** `# @rbs name: Array[String` is expected to fail `Style/RbsInline/InvalidTypes`. If it does not, use `# : () -> void` (`InvalidComment`). The test asserts the output names a `Style/RbsInline/` cop, not only a non-zero exit.
- **`Style` department interaction.** If a future omakase stops disabling `Style`, the plugin's own defaults would switch on all nineteen RBS cops. The settings test only asserts the ten are on, so it would not catch that; accepted, since every one of them is still gated by opt-in mode.
- **Consumers lose YARD lint silently** on their next `bundle update`. The CHANGELOG and README entries carry the opt-in line.
- **`--show-cops` on a nested department.** Settings tests read per-cop settings only (`Enabled`, `AllowMissingComment`). `Mode` is proven by behaviour (acceptance criterion 3), not by reading the department setting.
- Rejected: a new `config/yard.yml` layer. `intent.md` asks for opt-in through `YARD: Enabled: true`, and a layer adds a file for one line.
- Rejected: keeping the six `YARD/*` entries and adding `YARD: Enabled: false`. Verified that RuboCop then keeps all six on.
- Rejected: enabling all nineteen RBS cops. That demands annotations and fixes a signature style, which `intent.md` does not ask for.

## Out of scope

- Removing `rubocop-yard`.
- Demanding annotations in any file, opted in or not.
- Steep, `rbs validate`, `sig/` generation.
- Consuming projects, the dotfiles, and the Rails, RSpec and Capybara layers.
- A gem version bump or release.

## Proof

- A file with `# rbs_inline: enabled` and a malformed annotation fails lint under `default.yml` → `test/shared_configuration_test.rb` `test_a_malformed_inline_rbs_annotation_fails_lint_in_a_file_that_opts_in`
- A file with `# rbs_inline: enabled` and a valid annotation passes lint → `test/shared_configuration_test.rb` `test_a_valid_inline_rbs_annotation_passes_lint_in_a_file_that_opts_in`
- A file without `# rbs_inline: enabled` passes lint, however it is annotated → `test/shared_configuration_test.rb` `test_a_file_that_does_not_opt_in_passes_lint_however_it_is_annotated`
- A YARD comment with a wrong tag type no longer fails lint under `default.yml` alone → `test/shared_configuration_test.rb` `test_a_yard_comment_with_a_wrong_tag_type_passes_lint_under_the_shared_rules`
- A project that sets `YARD: Enabled: true` gets the YARD cops back → `test/shared_configuration_test.rb` `test_a_project_that_switches_yard_on_gets_the_yard_cops_back`
- The gem's test suite and its own RuboCop run are green → check: `bundle exec rake test && bundle exec rubocop`

Per changed file, the unit tests expected:

- `config/default.yml`: `test_the_shared_rules_switch_on_every_inline_rbs_rule` (the ten validating cops report `Enabled: true`), `test_the_shared_rules_never_demand_the_rbs_inline_magic_comment` (`RequireRbsInlineComment` reports `AllowMissingComment: true`), `test_the_shared_rules_accept_inline_rbs_annotations_without_a_space` (`Layout/LeadingCommentSpace` reports `AllowRBSInlineAnnotation: true`), `test_yard_rules_stay_off_until_a_project_asks_for_them` (`YARD/TagTypeSyntax` is `false` under `default.yml`, `true` under the fixture), and the existing `test_the_shared_rules_switch_on_every_rule_we_chose_over_omakase` without the YARD cops.
- `rubocop-eirvandelden.gemspec`: covered by `test_the_shared_rules_load_without_error` (RuboCop aborts when a listed plugin is missing) and the settings tests above (`fetch` raises when a cop is not registered).
- `test/fixtures/project_using_yard.yml`: exercised by the two YARD opt-in tests.

Test setup: no new gems in the test. Ruby sources are heredoc constants in `SharedConfigurationTest`: a malformed opted-in source (`# @rbs name: Array[String`), a valid opted-in source (`# @rbs name: String` above `def greet(name) #: String`), a source without the magic comment carrying the malformed annotation and a `#:` return annotation, and a YARD source with `# @param name [Array<String]`. Each opted-in source starts with `# rbs_inline: enabled` followed by a blank line. The valid source must report no offenses at all; the malformed source must report a `Style/RbsInline/` offense. The `lint` helper lints each as `lib/example.rb` through `--stdin`. Config fixture: `test/fixtures/project_using_yard.yml`.

---
Domain skills applied: dependencies (approved dependency, no version constraint like its neighbours, install with `bi`), ruby-style, rails-testing (Minitest conventions of the existing test).

## Critique

### Round 1 (codex -p terra)

- The YARD change exceeds the accepted scope: `intent.md` excludes removing the YARD cop settings, so removing the six entries needs an intent amendment, or a YARD opt-in layer with a changed acceptance criterion. → dismissed: verified that RuboCop keeps the six cops on while `default.yml` sets them `Enabled: true`, even with `YARD: Enabled: false` in the same file. Removing the entries is the only way to meet the accepted criteria 4 and 5 together. The entries restate `rubocop-yard`'s own defaults, so YARD behaviour on opt-in is unchanged. A YARD layer would change criterion 5 instead. The plan records this reading in Design decisions, and the report flags it for Etienne to confirm.
- The planned opted-in sources are not clean: `# rbs_inline: enabled` without a blank line after it fails `Layout/EmptyLineAfterMagicComment`, so step 1's "passes lint today" claim is false and step 5 would still fail. → fixed (verified the offense; Test setup and Risks now require a blank line after the magic comment in every opted-in source, the valid source must report no offenses, the malformed source must report a `Style/RbsInline/` offense, and step 1 now says why it fails)
