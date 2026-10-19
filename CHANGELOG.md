# Changelog

## Unreleased

- Check inline RBS annotations (`rubocop-rbs_inline`). The checks run only in files that start with `# rbs_inline: enabled`, and no file is required to opt in.
- `Layout/LeadingCommentSpace` accepts `#:` return annotations.
- YARD cops are off by default. A project that documents with YARD adds `YARD: Enabled: true` to its `.rubocop.yml`.

## 0.1.0

- First release. Collects the RuboCop rules that used to live in `~/.rubocop.yml`, where
  no project ever read them, and ships them as a gem that projects and CI can inherit.
