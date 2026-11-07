# Review: module-self-colon-form

## Round 1 — 2026-11-07T09:02Z — 0c7c826

No `REVIEW.md` or `REVIEW.local.md` exists; the default Bugs, Security, Compliance and Design passes ran. `bundle exec rake test`: 47 runs, 0 failures. `bundle exec rubocop`: no offenses. Security: nothing found. Compliance: every acceptance criterion and every `## Proof` test is present, and no test was weakened, skipped or deleted.

- [ ] Important: `# @rbs module-self: Minitest::Test -- depending on assertion methods`, a form RBS 4.2 documents as valid (`docs/inline.md`, "You can add a description after `--`"), still gets both `InvalidTypesAllowingColon` and `KeywordSeparatorAllowingColon` offenses: `COLON_FORM` hands the whole tail, description included, to `RBS::Parser.parse_type(require_eof: true)`, which raises. `rubocop -a` then strips the colon, which produces the form Steep rejects. Reproduced with `--stdin lib/test_helper.rb`. Strip a trailing ` -- …` before parsing the type, and add a test for it — `lib/rubocop/cop/style/rbs_inline/module_self_colon_form.rb:10` → fixed (fix: accept a module-self colon form with a description)
- [ ] Nit: `COLON_FORM.match(text.strip)&.[](:type)` reads more plainly as `text.strip[COLON_FORM, :type]` — `lib/rubocop/cop/style/rbs_inline/module_self_colon_form.rb:15` → fixed (refactor: read the module-self type with String#[])
- [ ] Nit: Law of Demeter: `annotation.source.comments.any?` reaches through the annotation into its source into its comments. Upstream `InvalidTypes#invalid_embedded?` uses the same chain and rbs-inline offers no shorter path, so a dismissal with that reason is acceptable — `lib/rubocop/cop/style/rbs_inline/invalid_types_allowing_colon.rb:22` → dismissed: upstream `InvalidTypes#invalid_embedded?` walks the same chain, and rbs-inline exposes no shorter path to the annotation comments

## Round 2 — 2026-11-07T10:02Z — 230f614

No `REVIEW.md` or `REVIEW.local.md` exists; the default Bugs, Security, Compliance and Design passes ran. `bundle exec rake test`: 48 runs, 0 failures. `bundle exec rubocop`: no offenses. Both round 1 fixes hold: `# @rbs module-self: Foo -- depending on its methods` passes, with a test (`d559809`), and `String#[]` reads the type (`230f614`).

Extra probes through `--stdin lib/x.rb` against `config/default.yml`: two colon annotations on one module pass; a broken and a valid colon annotation in one block flag only the broken line; an empty `module-self:` and `module-self: Foo[` are flagged by both cops; `# @rbs skip:` stays flagged. Security: nothing found. Compliance: every acceptance criterion and `## Proof` test is present; no test was weakened, skipped or deleted. Design: nothing new.

No findings.
