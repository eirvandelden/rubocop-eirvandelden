# Intent: Fix the Capybara layer test on main

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-16). Type: chore.
Delivery: autonomous

## Problem

CI on `main` is red since PR #8 (rubocop-minitest 0.40.0 → 0.41.0, which also pulled rubocop 1.91.0 → 1.92.0). The test `test_a_rails_project_using_capybara_keeps_both_sets_of_advice` asks RuboCop about `Capybara/CurrentPathExpectation`. RuboCop now answers "Unrecognized cop … Did you mean? Capybara/RSpec/CurrentPathExpectation". The test then fails with a YAML parse error, which hides the real cause. Nobody can tell from the suite whether a Rails project with the Capybara layer still keeps both sets of advice.

## Proposed outcome

The suite is green on `main` again. It still proves that stacking `capybara.yml` after `rails.yml` keeps the Rails advice and switches the Capybara advice on. The proof uses a Capybara cop that is not tied to a test framework, because the scenario is a Rails project whose system tests can be Minitest. When RuboCop rejects a cop name the suite asks about, the test fails with RuboCop's own "Unrecognized cop" message instead of a YAML parse error.

## Affected users and systems

- This gem's test suite (`test/shared_configuration_test.rb`) and its CI on `main`.
- Every later branch and Dependabot PR, which inherits the red CI until this lands.
- Consuming projects are not affected: the shipped config does not change.

## Constraints

- Follow RuboCop's current cop names; do not hold RuboCop or rubocop-capybara back.
- Permissions approved: none needed. No dependency, system tool, migration or deploy-file change (playbook rules 8, 9, 11, 12, 13). Any need for one is a stop-and-ask.

## In scope

- The stacking test checks a framework-neutral Capybara cop (for example `Capybara/SpecificFinders`) instead of `Capybara/CurrentPathExpectation`.
- The test helper that reads RuboCop's settings output reports an unrecognized cop name clearly instead of raising a YAML parse error.

## Out of scope

- Any change under `config/` — the shipped layers stay as they are.
- `Gemfile`, `Gemfile.lock`, the gemspec, and any pin on RuboCop or its plugins.
- `CHANGELOG.md` and `README.md`.
- The CI workflow under `.github/`.

## Acceptance criteria

- On the current lockfile (rubocop 1.92.0, rubocop-capybara 3.0.0), `bundle exec rake test` passes, and CI on the PR is green.
- A Rails project that lists `default.yml`, `rails.yml` and `capybara.yml` in that order has every Rails rule the suite checks switched on, and has the checked framework-neutral Capybara rule switched on.
- When the suite asks RuboCop about a cop name it does not recognise (for example `Capybara/CurrentPathExpectation` today), the failing test names that cop and RuboCop's "Unrecognized cop" message, not a YAML syntax error.
- If `capybara.yml` stopped switching the Capybara department on, the stacking test fails.

## Open questions

None.
