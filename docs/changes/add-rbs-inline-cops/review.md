# Review: add-rbs-inline-cops

## Round 1 — 2026-10-19T12:07Z — f7e43f4 (codex)

No findings.


## Round 2 (claude) — 2026-10-19T12:08Z — f7e43f4

Tests (21 runs, 0 failures) and RuboCop (no offenses) are green. All six acceptance criteria map to a named test in the plan's Proof, and every named test exists. No existing test was weakened, skipped or deleted.

- [ ] Nit: The diff moves the private helpers `run_rubocop` and `departments_offered_by` to new positions, and the moves are unrelated to the task and add churn to the review. Only `lint` is new. — `test/shared_configuration_test.rb:228` → dismissed: Obsession/MethodOrder requires the new `lint` helper above its callees, and `bundle exec rubocop` must stay green, so the reorder is forced by the lint rule
- [ ] Nit: Test constants (`VALID_OPTED_IN`, `NOT_OPTED_IN`, `WRONG_YARD_TAG_TYPE`, `VALIDATING_RBS_RULES`) sit between test methods instead of together at the top of the class. — `test/shared_configuration_test.rb:33` → dismissed: the file already keeps each constant next to the tests that use it (`RAILS_RULES`, `FRAMEWORK_NEUTRAL_CAPYBARA_RULE`, `RULES_WE_TURN_OFF`), so the new constants follow the surrounding code
- [ ] Nit: Removing the six `YARD/*` entries goes past `intent.md` out-of-scope ("removing the YARD cop settings"). The plan records the reason and the Codex critique dismissed it, but Etienne has not confirmed it. — `config/default.yml:123` → dismissed: Etienne confirmed in this session that removing the six `YARD/*: Enabled: true` entries is within scope, because RuboCop otherwise keeps those cops on despite `YARD: Enabled: false`
