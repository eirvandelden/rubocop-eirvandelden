# Changelog

## Unreleased

- Rails projects no longer need a `#:` signature in `db/data`, `db/cable_migrate` or `db/queue_migrate`, the same as `db/migrate`: they are run-once scripts.
- A valid `# @rbs module-self: X` passes lint, as Steep's inline mode requires. `Style/RbsInline/InvalidTypes` and `KeywordSeparator` are replaced by `InvalidTypesAllowingColon` and `KeywordSeparatorAllowingColon`, which flag everything else as before. The gem now ships Ruby under `lib/`.

## 1.0.0

- **Breaking:** every non-test file is now checked for inline RBS annotations (`rubocop-rbs_inline`, `Mode: opt_out`), with no magic comment. Public methods and `attr_*` need a `#:` signature, and `Data.define` and `Struct.new` attributes need a `#:` type. Projects fail lint until they annotate.
- `# rbs_inline: disabled` is the only way out of the checks. A leftover `# rbs_inline: enabled` is flagged, and autocorrect removes it. Migrations are exempt in Rails projects (`config/rails.yml`), and every `test/` or `spec/` folder, nested ones included, stays unchecked.
- `Layout/LeadingCommentSpace` accepts `#:` return annotations.
- YARD cops are off by default. A project that documents with YARD adds `YARD: Enabled: true` to its `.rubocop.yml`.
- Requires Ruby 4.0 or newer (was 3.4).
- Requires RuboCop 1.92 or a later 1.x (was any version). RuboCop 1.82 is the first release that knows Ruby 4.0, and 1.92 is the release this gem's CI tests.

## 0.1.0

- First release. Collects the RuboCop rules that used to live in `~/.rubocop.yml`, where
  no project ever read them, and ships them as a gem that projects and CI can inherit.
