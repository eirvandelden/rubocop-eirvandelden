# Review: rbs-inline-cop-opt-out

## Round 1 — 2026-10-21T18:51Z — 9da7b59

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes (Bugs, Security, Compliance, Design) ran. `bundle exec rake test` (37 runs, 0 failures) and `bundle exec rubocop` (no offences) are green.

Compliance, criterion → proof:

- Malformed `# @rbs` without a magic comment fails → `test_a_malformed_inline_rbs_annotation_fails_lint_without_a_magic_comment`
- Unannotated public `def` fails; `#:` above it passes → `test_a_public_method_without_a_signature_fails_lint`, `test_a_public_method_with_a_signature_above_it_passes_lint`
- Private method passes → `test_a_private_method_without_a_signature_passes_lint`
- `attr_reader` fails / passes with `#: String` → `test_a_public_attribute_without_a_type_fails_lint`, `test_a_public_attribute_with_a_trailing_type_passes_lint`
- `Data.define` and `Struct.new` → `test_a_data_class_fails_lint_until_each_attribute_has_a_type`, `test_a_struct_class_fails_lint_until_each_attribute_has_a_type`
- `# rbs_inline: disabled` passes → `test_a_file_that_opts_out_passes_lint_however_it_is_annotated`
- Leftover `# rbs_inline: enabled` flagged and autocorrected → `test_a_leftover_rbs_inline_magic_comment_fails_lint`, `test_autocorrect_removes_a_leftover_rbs_inline_magic_comment`
- `# @rbs skip` passes → `test_a_method_marked_rbs_skip_passes_lint_without_a_signature`
- `test/` and `spec/` pass → `test_an_unannotated_public_method_in_a_test_or_spec_passes_lint`
- Rails migration passes, controller fails → `test_a_rails_project_does_not_demand_a_signature_on_a_migration`, `test_a_rails_project_demands_a_signature_on_a_controller_action`
- Version `1.0.0` and CHANGELOG → `test_the_gem_reports_version_one`; the plan's `sed … | grep` check prints both lines
- Fallback and `ruby-style` skill criteria → dotfiles pull request, per the plan's Coordinator decisions; not in this branch
- Suite and RuboCop green → verified
- Every `## Proof` test name exists. The four removed tests are the reversed opt-in behaviours the plan names; no other test is weakened, skipped or deleted.

Findings:

- [ ] Nit: `AGENTS.md` (and `CLAUDE.md`, its symlink) still says `rake install` lets `~/.rubocop.yml` "(which inherits this gem)" lint loose files. This branch corrects that claim in the README's "Loose Ruby files" section and drops `rake install` there, so the agent instructions now contradict the README — `AGENTS.md:15` → fixed (docs: say the dotfiles fallback carries its own copy of the rules)
- [ ] Nit: `autocorrect` splits on the `====================` separator, but with `--stderr` stdout holds only the corrected source (verified), as its own comment says. The split is dead code that contradicts the comment above it — `test/shared_configuration_test.rb:401` → fixed (test: drop the dead report split from autocorrect)

## Round 2 — 2026-10-21T18:55Z — 75082e6

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes (Bugs, Security, Compliance, Design) ran. `bundle exec rake test` (37 runs, 130 assertions, 0 failures) and `bundle exec rubocop` (4 files, no offences) are green. The plan's CHANGELOG check prints both lines.

Round 1 fixes verified:

- `AGENTS.md` (and the `CLAUDE.md` symlink) no longer claims `~/.rubocop.yml` inherits the gem; the new gotcha matches the README's "Loose Ruby files" section.
- `autocorrect` returns stdout as the corrected source, with no dead split; its comment matches the code.

Extra checks:

- Bugs: `rails.yml` loads `rubocop-rbs_inline` a second time without a warning, and a signed controller action passes under `test/fixtures/rails_project.yml`. The plugin's `MissingTypeAnnotation` default has no `Exclude`, so the cop-level migration `Exclude` in `rails.yml` drops nothing; the department `Exclude` of `test/**` and `spec/**` still merges, as `test_a_rails_project_does_not_demand_a_signature_in_a_test` proves.
- Security: configuration and tests only; no secrets, no new dependency (the `~> 2.0` constraint tightens an existing one).
- Compliance: no linter disable comments, no skipped tests; the four removed tests are the reversed opt-in behaviours the plan names. Commits are small and single-purpose.
- Design: layering holds — `default.yml` owns the mode and cops, `rails.yml` owns the migration exclusion and does not inherit `default.yml`.

Findings:

None.

## Round 3 — 2026-10-21T19:20Z — d806c33

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes (Bugs, Security, Compliance, Design) ran over the commits since round 2 (`5089711`, `d806c33`). `bundle exec rake test` (38 runs, 134 assertions, 0 failures) and `bundle exec rubocop` (4 files, no offences) are green.

Extra checks:

- Bugs: the department `Exclude` in `config/default.yml` replaces the plugin's `test/**/*` and `spec/**/*` with a superset, so the root folders stay excluded. Probed with `--stdin`: under `config/default.yml` and `test/fixtures/rails_project.yml`, `engines/shop/test/…` and `engines/shop/spec/…` pass, `lib/greeter.rb` fails, and a nested `db/migrate` file passes only in the Rails stack. `rails.yml`'s cop-level migration `Exclude` does not drop the department `Exclude`.
- Regression proof: the pre-fix `config/default.yml` (`d806c33^`) flags `engines/shop/test/greeter_test.rb` with `MissingTypeAnnotation`, so `test_an_unannotated_public_method_in_a_nested_test_or_spec_passes_lint` fails before the fix and passes after it.
- Security: configuration, tests and docs only; no new dependency.
- Compliance: the new test matches the Proof name in the plan's Coordinator decisions. README and CHANGELOG say nested folders stay unchecked. No disable comments, no skipped tests.
- Design: the exclusion lives in `default.yml`, the layer that owns the inline RBS cops; the comment above `Style/RbsInline` names why the `**/` is there.

Findings:

None.
