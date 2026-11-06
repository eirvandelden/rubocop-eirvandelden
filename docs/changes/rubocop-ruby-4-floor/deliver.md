# Delivery account: rubocop-ruby-4-floor

## Behaviour delivered

- `rubocop-eirvandelden.gemspec` now requires `rubocop ~> 1.92`. A fresh resolve of a project on this gem picks RuboCop 1.92 or a later 1.x, which knows Ruby 4.0. When no such RuboCop fits, Bundler refuses to resolve instead of falling back to an old RuboCop.
- `Gemfile.lock` PATH section carries the same requirement; the GEM section keeps RuboCop 1.92.1.
- `CHANGELOG.md` `## 1.0.0` says the gem requires RuboCop 1.92 or a later 1.x.
- RuboCop 1.82.0 is the first release that knows Ruby 4.0 (changelog #14644; `KNOWN_RUBIES` in v1.81.7 ends at 3.5, in v1.82.0 it holds 4.0). Etienne chose 1.92 as the floor because this is his own software and its projects can upgrade.

## Evidence

Fresh `bundle lock` (no lockfile, real index) in scratch projects that depend on this gem by path:

- Control, `origin/main` gemspec plus `gem "prism", "2.0.0"`: resolves RuboCop 1.74.0. This reproduces the appkit CI failure (run 40345668764, appkit PR #24).
- This branch plus `gem "prism", "2.0.0"`: refused. "every version of rubocop-eirvandelden depends on rubocop ~> 1.92 … requires prism ~> 1.7 … version solving has failed."
- This branch plus `gem "rubocop", "1.74.0"`: refused. "rubocop ~> 1.92 is required. So, because Gemfile depends on rubocop = 1.74.0, version solving has failed."
- This branch, no pins: resolves RuboCop 1.92.2 with prism 1.9.0.

## Check results

- `BUNDLE_FROZEN=true bundle exec rake test`: 42 runs, 145 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec rubocop`: no offenses.
- Regression test `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` was committed first (d34ee64) and failed before the fix: the unconstrained requirement accepted 1.74, 1.91 and 2.0.
- Brakeman and Bundler Audit: not applicable; this gem has no Rails app and no bundler-audit in its bundle.

## Review outcome

- Plan: Codex critique, round 1, two findings, both fixed.
- Claude reviewer, round 1: one nit (test name claimed more than it proved), fixed in "Name the RuboCop floor test after what it proves". The bugfix test guard blocked the rename; Claude lifted `Reproduction: committed` from `plan.md` for that one edit and restored it unchanged.
- Claude reviewer, round 2: no open findings. Codex review was not enabled.

## Notes

- The branch was rebased onto `origin/main` (d91402e) before review.
- Commit signing failed three times through 1Password during the plan stage; Etienne unlocked 1Password and every commit is signed.
- Deferred, out of scope: the appkit fix in `rakelib/signatures.rake:12` stays in appkit PR #24, after this gem merges. Floors on the other bundled cop gems and the gem version number are untouched.
