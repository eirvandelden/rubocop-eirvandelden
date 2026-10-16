# Review: fix-capybara-test-on-main

## Round 1 — 2026-10-16T18:11Z — c545474 (codex)

No findings.

## Round 2 (claude) — 2026-10-16T18:13Z — c545474

No findings.

Checked: `bundle exec rake test` green (12 runs, 0 failures); `bundle exec rubocop` clean; diff touches only `test/shared_configuration_test.rb` outside the change folder.

Compliance:

- Criterion 1 (suite green on current lockfile, CI green) → `bundle exec rake test` green locally; CI checked by `deliver` on the PR.
- Criterion 2 (Rails rules and framework-neutral Capybara rule on) → `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`.
- Criterion 3 (unrecognized cop fails with RuboCop's message) → `test_a_rule_rubocop_does_not_recognise_fails_with_rubocops_own_message`.
- Criterion 4 (layer keeps Capybara advice on) → `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`, behavioural reading as recorded in plan.md Risks.
- Every test named in plan.md `## Proof` exists. No existing test was weakened, skipped or deleted.
