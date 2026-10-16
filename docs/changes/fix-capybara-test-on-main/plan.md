# Plan: Fix the Capybara layer test on main

From `intent.md` (2026-10-16). Status: accepted.

## Context

`bundle exec rake test` on `main` fails with 1 error in 11 runs. The error is `Psych::SyntaxError` from `settings_for` (`test/shared_configuration_test.rb:139`), called by `test_a_rails_project_using_capybara_keeps_both_sets_of_advice` (line 67).

Cause, verified on the current lockfile (rubocop 1.92.0, rubocop-capybara 3.0.0): rubocop-capybara 3.0 moved the RSpec-only cops under `Capybara/RSpec/`. `rubocop --show-cops Capybara/CurrentPathExpectation` now prints `Unrecognized cop: Capybara/CurrentPathExpectation.` and `Did you mean? Capybara/RSpec/CurrentPathExpectation` above the YAML and exits with status 2. `settings_for` ignores the exit status and feeds that text to `YAML.safe_load`, which raises.

Facts checked while planning:

- `rubocop --show-cops Capybara/SpecificFinders,Rails/IndexBy -c test/fixtures/rails_project_using_capybara.yml` exits 0 and shows both with `Enabled: true`.
- `Capybara/SpecificFinders` is in the framework-neutral part of rubocop-capybara 3.0 (not under `Capybara/RSpec/`).
- With `Capybara: Enabled: false` in the Capybara layer, `Capybara/SpecificFinders` shows `Enabled: false`.
- With the `plugins: - rubocop-capybara` line removed from the layer, RuboCop exits 2 (unrecognized department, or `Unrecognized cop` when the department line is gone too).
- With the `Capybara: Enabled: true` block removed but the plugin kept, `Capybara/SpecificFinders` still shows `Enabled: true`: rubocop-capybara 3.0's own `config/default.yml` enables the department and the cop. See Risks.
- An unknown name gives `Unrecognized cop: <name>.` on its own line, sometimes followed by `Did you mean? <name>`, and exit status 2. A run with only recognized names exits 0.

## Design decisions

- **Cop to check: `Capybara/SpecificFinders`.** The intent names it as the example. It is framework-neutral, enabled by default in rubocop-capybara 3.0, and has existed since 2.13. Put it in a named constant with a one-line comment that says why it is framework-neutral, so a later rename shows up as a clear failure on one line.
- **Fail on RuboCop's exit status, before YAML parsing.** `settings_for` reads the status from `run_rubocop` and asserts success. The failure message is RuboCop's own complaint lines — every output line that starts with `Unrecognized cop`, `Did you mean?` or `Error:`. When no line matches, the message is the whole output, so no failure is ever silent. A status check is more robust than sniffing the text for YAML, because RuboCop already signals the problem through the status.
- **Prove the helper with its own test, using a made-up cop name.** Criterion 3 is behaviour of the suite. A test that calls `settings_for` with `Capybara/NoSuchRule` and asserts the raised `Minitest::Assertion` message names the cop and contains `Unrecognized cop` proves it. A made-up name stays unrecognized forever; `Capybara/CurrentPathExpectation` could come back in a later release.
- **Keep the test name `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`** and its fixture. The scenario it describes has not changed.
- **No change under `config/`.** The intent puts it out of scope.

## Integration points

- RuboCop's `--show-cops` output format and exit status (rubocop 1.92.0).
- rubocop-capybara 3.0.0 cop names.
- CI workflow `.github/workflows/ci.yml` runs `bundle exec rubocop -f github` and `bundle exec rake test`. Not edited.
- `.rubocop.yml` lints this repository with `config/default.yml`. The test file must pass it.

## Files that change

- `test/shared_configuration_test.rb`
  - New constant for the framework-neutral Capybara cop (`Capybara/SpecificFinders`), used by the stacking test in place of `"Capybara/CurrentPathExpectation"`.
  - `settings_for` asserts RuboCop exited successfully before it parses YAML, with RuboCop's complaint lines as the message.
  - New private helper that extracts RuboCop's complaint lines from the output (falls back to the whole output).
  - New test for criterion 3.

Nothing else changes. Ruby style: methods at most 5 lines, `rescue => error` if any rescue is needed (none expected), no linter disable comments.

## Order of work

1. Write the acceptance test for criterion 3: `test_a_rule_rubocop_does_not_recognise_fails_with_rubocops_own_message`. It calls `settings_for([ "Capybara/NoSuchRule" ], "test/fixtures/rails_project_using_capybara.yml")` inside `assert_raises(Minitest::Assertion)` and asserts the message includes `Unrecognized cop: Capybara/NoSuchRule`. Run it alone (`bundle exec ruby -Itest test/shared_configuration_test.rb -n test_a_rule_rubocop_does_not_recognise_fails_with_rubocops_own_message`). Watch it fail: today `settings_for` raises `Psych::SyntaxError`, not `Minitest::Assertion`.
2. Change `settings_for` to keep the status from `run_rubocop`, assert `status.success?` with the complaint message, then parse. Add the complaint-lines helper. Run the step-1 test; it passes.
3. Run the stacking test alone. It now fails with `Unrecognized cop: Capybara/CurrentPathExpectation.` and `Did you mean? Capybara/RSpec/CurrentPathExpectation` in the message — no `Psych::SyntaxError`. This is the regression test going red for the right reason.
4. Replace `"Capybara/CurrentPathExpectation"` in the stacking test with the new constant. Run the stacking test alone; it passes.
5. Mutation check for criterion 4, never committed: set `Capybara: Enabled: false` in `config/capybara.yml`, run the stacking test, watch it fail naming `Capybara/SpecificFinders`. Then remove the `plugins` entry instead, run it, watch it fail with RuboCop's complaint. Restore the file with `git checkout -- config/capybara.yml` and confirm `git status` shows it clean.
6. Run the full suite: `bundle exec rake test`. All green.
7. Run `bundle exec rubocop`. Fix every offence in the test file without disable comments.
8. Re-read the diff; only `test/shared_configuration_test.rb` changes.

## Risks

- **Criterion 4 against the current plugin defaults.** rubocop-capybara 3.0 enables its department and its cops by default. If someone deletes only the `Capybara: Enabled: true` block from `capybara.yml`, Capybara cops stay on, behaviour does not change, and the stacking test still passes. The test does fail when the layer switches the department off (`Enabled: false`) or stops loading the plugin — the two edits that remove Capybara advice. A test that fails on a no-op edit would have to read `capybara.yml` as text, which tests the file, not the behaviour; not planned. This reading of criterion 4 goes to Etienne as an open decision: either the criterion means "the layer keeps Capybara advice on" (this plan), or he wants an extra test-only assertion that `config/capybara.yml` keeps `Capybara: Enabled: true`. The extra assertion would touch only the test file, so it can follow without replanning.
- **`assert_predicate` inside `settings_for` adds one assertion to every caller.** `Minitest/MultipleAssertions` is set to `Max: 8`; no test comes near. The extra assertion count is harmless.
- **Other callers of `settings_for` start failing on a non-zero exit.** Today every other caller passes, so each RuboCop run there exits 0. Step 6 confirms it.
- **Future renames of `Capybara/SpecificFinders`.** Would now fail with RuboCop's own message, which is the point of criterion 3.
- **Rejected: switching to `Capybara/RSpec/CurrentPathExpectation`.** The fixture is a Rails project whose system tests can be Minitest; an RSpec-only cop does not prove what the scenario claims.
- **Rejected: rescuing `Psych::SyntaxError`.** It still hides RuboCop's status and would mislabel any other YAML problem.

## Out of scope

- Any edit under `config/`, including the mutation in step 5 (reverted before commit).
- `Gemfile`, `Gemfile.lock`, the gemspec, any pin on RuboCop or its plugins.
- `CHANGELOG.md`, `README.md`, `.github/`.

## Proof

- On the current lockfile, `bundle exec rake test` passes, and CI on the PR is green → `bundle exec rake test` (all of `test/shared_configuration_test.rb`); check: `gh pr checks` on the delivered PR shows `lint` and `test` green.
- A Rails project listing `default.yml`, `rails.yml`, `capybara.yml` has every checked Rails rule and the checked framework-neutral Capybara rule on → `test/shared_configuration_test.rb` `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`
- An unrecognized cop name fails with that cop's name and RuboCop's "Unrecognized cop" message, not a YAML error → `test/shared_configuration_test.rb` `test_a_rule_rubocop_does_not_recognise_fails_with_rubocops_own_message`
- If `capybara.yml` stopped switching the Capybara department on, the stacking test fails → `test/shared_configuration_test.rb` `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`; check: step 5 mutations (`Capybara: Enabled: false`; plugin removed) each turn it red, then `git checkout -- config/capybara.yml`. Limit: deleting only the `Capybara: Enabled: true` block changes no behaviour on rubocop-capybara 3.0, so this test does not catch it and the plan does not claim it does. Whether to add a test that reads `config/capybara.yml` as text is Etienne's decision (see Risks).

Per changed file, the unit tests expected:

- `test/shared_configuration_test.rb`: `settings_for fails with RuboCop's complaint when RuboCop rejects a name`, `the Capybara stacking test checks a framework-neutral cop`. The other nine existing tests stay unchanged and green.

Test setup: existing fixture `test/fixtures/rails_project_using_capybara.yml`; real `bundle exec rubocop` runs, nothing faked.

---
Domain skills applied: ruby-style, rails-testing (Minitest conventions).

## Critique

### Round 1 (codex terra)

- Criterion 4 is not fully met: deleting only the `Capybara: Enabled: true` block leaves `Capybara/SpecificFinders` on, because rubocop-capybara enables it by default, so the stacking test cannot catch that edit; either reword the criterion or add a text assertion on `config/capybara.yml` → fixed (Proof and Risks now state the limit and no longer claim the test catches that edit; the choice between the behavioural reading and an extra text assertion is raised as a Decision needed in the report, since it reinterprets an accepted criterion)
