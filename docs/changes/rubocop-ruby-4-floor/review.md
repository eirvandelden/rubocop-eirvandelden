# Review: rubocop-ruby-4-floor

## Round 1 — 2026-11-06 20:50 UTC — ef93542

Checks: `BUNDLE_FROZEN=true bundle exec rake test` green (42 runs, 0 failures). `bundle exec rubocop` green. `Gemfile.lock` diff against `origin/main` is only the PATH line `rubocop (~> 1.92)`; the GEM section keeps `rubocop (1.92.1)`. No REVIEW.md or REVIEW.local.md exists, so the default passes ran.

Bugs: none. `~> 1.92` accepts 1.92.0 up to, not including, 2.0. The regression test commit (d34ee64) precedes the fix commit (8959888) and fails against the unconstrained requirement, which accepts all six candidates.

Security: none. The change only narrows a dependency constraint.

Compliance:
- A project cannot resolve this gem next to RuboCop 1.74, nor next to 1.91 → `test_the_gem_accepts_only_a_rubocop_its_ci_tests` (1.74 and 1.91 are absent from the accepted set).
- RuboCop 1.92.0, the locked 1.92.1 and any later 1.x satisfy the gemspec; RuboCop 2.0 does not → same test (1.92.0, 1.92.1 and 1.99 are in the set; 2.0 is not).
- The changelog tells consumers that the gem now needs RuboCop 1.92 or newer → `CHANGELOG.md:14`, inside `## 1.0.0`.
- Every test named in `plan.md`'s Proof exists. No existing test was weakened, skipped or deleted.

Design: no public method added, no call chain, no query. The glossary has no `Avoid:` list.

- [ ] Nit: The test name says the gem accepts "only a RuboCop its CI tests", but the test asserts that 1.99 is accepted, a release CI never runs. The comment above it calls 1.92 "the release its CI tests", while CI runs whatever `Gemfile.lock` holds (1.92.1 now, later releases after a lockfile bump). Name the behaviour the assertion proves instead, for example `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x`, and say in the comment that 1.92 is the floor. — `test/shared_configuration_test.rb:263` → fixed (Name the RuboCop floor test after what it proves)

## Round 2 — 2026-11-06 — d4d791e

Checks: `BUNDLE_FROZEN=true bundle exec rake test` green (42 runs, 145 assertions, 0 failures). `bundle exec rubocop` green. `Gemfile.lock` diff against `origin/main` is still only the PATH line `rubocop (~> 1.92)`. No REVIEW.md or REVIEW.local.md exists, so the default passes ran.

Round 1 nit verified: 156871b renames the test to `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` and its comment now calls 1.92 the floor. d4d791e updates `plan.md` to the same name. The old name survives only in Round 1 above, as history.

Bugs: none. Security: none.

Compliance:
- A project cannot resolve this gem next to RuboCop 1.74, nor next to 1.91 → `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` (1.74 and 1.91 are absent from the accepted set).
- RuboCop 1.92.0, the locked 1.92.1 and any later 1.x satisfy the gemspec; RuboCop 2.0 does not → same test.
- The changelog tells consumers that the gem now needs RuboCop 1.92 or newer → `CHANGELOG.md:14`, inside `## 1.0.0`.
- The regression test commit (d34ee64) still precedes the fix (8959888).

Design: no change since Round 1.

No open findings.
