# Plan: Update all dependencies

From `intent.md` (2026-10-19). Status: accepted.

## Design decisions

- Proof is a list of command checks, not new Minitest tests. Every acceptance criterion is a fact about `Gemfile.lock`, `.ruby-version` or a tool's exit status. A Ruby test that parses the lockfile would pin versions that the next update must edit again, and it would test Bundler rather than this gem. The existing `test/shared_configuration_test.rb` is the behavioural proof that the updated cop gems still produce the shared rules. Step 1 is therefore the first failing check, not a new failing test.
- Order: Ruby first, then Bundler, then gems. `Gemfile` reads `ruby file: ".ruby-version"`, so Bundler refuses to run when the active Ruby and `.ruby-version` disagree. Bumping `.ruby-version` first makes `rv` select 4.0.7 for every later command. Bundler 4.0.23 is installed under that Ruby. The gems are resolved last, under the final Ruby and Bundler.
- Explicit Bundler flags instead of a bare `bundle update`. `bundle update --help` documents `--all` (update every gem), `--ruby` (lock the running Ruby) and `--bundler[=VERSION]` (lock the given Bundler). The plan passes `--bundler=4.0.23` with an exact version so the locked Bundler is deterministic, and invokes `bundle _4.0.23_` so the run itself uses the new Bundler rather than the 4.0.19 that `BUNDLED WITH` auto-selects. The `_4.0.23_` prefix is redundant for the lock result, but it makes the step independent of auto-switching.
- `bundle update` already installs what it resolves. If any gem is still missing afterwards, install it with `bi`, never `bundle install` (playbook rule 11).
- Bundler Audit is not in the `Gemfile` or in CI. The repository does not use it, so the intent's criterion does not bind. The global `bundle-audit` (0.9.3) is still run once as evidence, per playbook §4. It adds no dependency. A reported vulnerability is a blocker for the report, not something to fix in this change.
- `CHANGELOG.md` records consumer-visible config changes, not lockfile or Ruby bumps: a gem's `Gemfile.lock` and `.ruby-version` never reach a consumer. Add an `## Unreleased` entry only if a `config/*.yml` file changes. If no config file changes, `CHANGELOG.md` stays untouched.

## Integration points

- `rv`, the Ruby version manager: it reads `.ruby-version` to pick the Ruby. Ruby 4.0.7 is already installed (`rv ruby list` shows `~/.local/share/rv/rubies/ruby-4.0.7`). Nothing is installed through `rv`.
- RubyGems: `gem install bundler -v 4.0.23` (approved in `intent.md`). `gem search -r --exact bundler` confirms 4.0.23 is published.
- The gem source `https://gem.coop` in `Gemfile`.
- CI (`.github/workflows/ci.yml`) sets up Ruby with `spinel-coop/setup-rv` and `ruby-version: current`, then runs `bundle exec rubocop -f github` and `bundle exec rake test`. CI is not edited. The pull request's CI run is the external check that the new `.ruby-version` and lockfile install cleanly.
- Consumers: they resolve their own lockfile. This change does not alter what they get, unless a `config/*.yml` file changes.

## Files that change

- `.ruby-version` — `4.0.5` becomes `4.0.7`.
- `Gemfile.lock` — every gem at its latest allowed version (at least `rubocop-capybara` 3.1.0 and `uri` 1.1.2), `RUBY VERSION` becomes `ruby 4.0.7`, `BUNDLED WITH` becomes `4.0.23`, and the `CHECKSUMS` section updates to match.
- `config/*.yml` — only if an updated cop gem forces it (a renamed or removed cop that makes `rake test` or `bundle exec rubocop` fail). Not expected: `bundle outdated` on 2026-10-19 lists only `rubocop-capybara` and `uri`.
- `CHANGELOG.md` — only together with a `config/*.yml` change, under `## Unreleased`.

Nothing else changes: not the `Gemfile`, not the gemspec, not `test/`, not `.github/`.

## Order of work

1. Run the first failing check: `bundle outdated`. It must exit non-zero and list `rubocop-capybara` (3.0.0 → 3.1.0) and `uri` (1.1.1 → 1.1.2). Record that output as the "before" evidence.
2. Set `.ruby-version` to `4.0.7`. Run `ruby -v` in the worktree and confirm it prints `ruby 4.0.7`. If it still prints 4.0.5, stop and report: never switch Rubies another way (playbook rule 8).
3. Run `gem install bundler -v 4.0.23`. Confirm `gem list bundler` lists 4.0.23. Install nothing else.
4. Run `bundle _4.0.23_ update --bundler=4.0.23 --ruby`. Confirm `Gemfile.lock` ends with `RUBY VERSION` `ruby 4.0.7` and `BUNDLED WITH` `4.0.23`, and `bundle -v` now prints 4.0.23.
5. Run `bundle update --all`. Confirm `Gemfile.lock` lists `rubocop-capybara (3.1.0)` and `uri (1.1.2)`. Run `bundle check`; if it reports missing gems, run `bi`.
6. Run `bundle outdated`. It must exit 0 and report nothing outdated.
7. Run `bundle exec rake test`. If it fails, find which updated gem caused it (`git diff Gemfile.lock`, the gem's changelog). If the fix is a forced config change (a renamed cop), make it in the `config/*.yml` layer that owns that cop and add a `CHANGELOG.md` entry under `## Unreleased`. If the fix would switch a cop on or off, stop and report a `Decision needed:` line instead. Never edit the test.
8. Run `bundle exec rubocop`. An obsolete or invalid configuration warning is fixed in the `config/*.yml` layer that owns the cop, under the same rule as step 7. An offence in a Ruby file (`Rakefile`, the gemspec, `test/`) is out of this change's file scope: stop and report it as a `Decision needed:` line, never fix it through a disable comment or a `.rubocop.yml` change. With the current scope no Ruby file changes, so no new offence is expected.
9. Scan the output of steps 7 and 8 for deprecation or obsolete-config warnings from RuboCop or a cop gem (for example "obsolete parameter" or "has been renamed"). The dependencies skill says to fix deprecations as part of the upgrade. Fix one that the update introduced in the owning `config/*.yml` layer, under the same rule as step 7. Ignore the RDoc "already initialized constant" warnings: they come from two RDoc versions in the global gem directory, not from this repository.
10. Run `bundle-audit check --update` and record the result.
11. Re-read the full diff (`git diff main`). Every hunk must be in "Files that change". Commit in small steps, one logical change each: `.ruby-version` and the Bundler/Ruby lockfile lines together (step 4 rewrites both); the gem updates (step 5) separately; any forced config change and its changelog entry separately.

## Risks

- `rv` may not pick up the new `.ruby-version` in a non-interactive shell. Step 2 checks it before anything else runs. The plan never uses another version manager.
- Bundler auto-switching: with `BUNDLED WITH 4.0.19` still in the lockfile, a plain `bundle` call runs 4.0.19. Step 4 invokes `bundle _4.0.23_` so the run uses the new Bundler; `--bundler=4.0.23` sets the locked version either way.
- `rubocop-capybara` 3.1.0 may add cops. `config/default.yml` sets `NewCops: enable`, so any pending Capybara cop becomes active for projects that load `config/capybara.yml`. That is existing policy, not a config change made here, so it is not a reason to edit `capybara.yml`. Consumers see it only after their own `bundle update rubocop-eirvandelden`. If the release renames or removes `Capybara/SpecificFinders` (named in the test as `FRAMEWORK_NEUTRAL_CAPYBARA_RULE`), `rake test` fails, and step 7 handles it.
- `CHECKSUMS` in `Gemfile.lock`: Bundler 4 writes checksums. A gem source that serves a different checksum than recorded makes `bundle update` refuse. Do not delete the section by hand; report the mismatch.
- CI uses `ruby-version: current`. If `setup-rv` resolves that to a Ruby other than 4.0.7, `ruby file: ".ruby-version"` in the `Gemfile` fails the CI install. CI changes are out of scope. If that happens, report it as `Decision needed:`.
- Rejected: writing a Minitest test that asserts lockfile versions. It would test Bundler, not this gem, and break on every future update.
- Rejected: changing gemspec constraints or `required_ruby_version`. Out of scope, and `test_the_gem_asks_for_a_ruby_its_projects_actually_run` guards `>= 3.4`.

Out of scope, explicitly: adding or removing gems, gemspec changes, `.github/workflows/ci.yml`, enabling or disabling cops the update does not force, releasing a gem version, installing any Ruby.

## Proof

- `Gemfile.lock` lists `rubocop-capybara` 3.1.0 and `uri` 1.1.2, and `bundle outdated` reports nothing → check: `grep -E '^    (rubocop-capybara \(3\.1\.0\)|uri \(1\.1\.2\))$' Gemfile.lock` prints both lines, and `bundle outdated` exits 0
- `Gemfile.lock` records `BUNDLED WITH 4.0.23` → check: `tail -2 Gemfile.lock` prints `BUNDLED WITH` then `   4.0.23`
- `.ruby-version` reads `4.0.7` → check: `cat .ruby-version` prints `4.0.7`, and `ruby -v` in the worktree prints `ruby 4.0.7`
- `rake test` passes with the updated gems → `test/shared_configuration_test.rb` (whole file), run as `bundle exec rake test`
- RuboCop passes on this repository with the updated gems → check: `bundle exec rubocop` exits 0
- Bundler Audit reports no vulnerabilities, if the repository uses it → check: `bundle-audit check --update` (the repository does not use it; run as evidence only)

Per changed file, the unit tests expected:
- `.ruby-version`, `Gemfile.lock`: none new. The existing `SharedConfigurationTest` covers the behaviour the updated gems could break, notably `test_the_shared_rules_load_without_error`, `test_the_shared_rules_offer_cops_from_every_bundled_plugin`, `test_projects_using_capybara_can_add_its_cops` and `test_a_rails_project_using_capybara_keeps_both_sets_of_advice`.
- `config/*.yml` (only if forced): no new test unless the change alters behaviour a test does not already cover; a renamed cop is covered by `test_the_shared_rules_load_without_error` and the fixture-based layer tests.

Test setup: none beyond the existing fixtures in `test/fixtures/`. The tests shell out to `bundle exec rubocop`, so they run against the updated lockfile without changes.

---
Domain skills applied: dependencies, ruby-upgrade (patch-level only: 4.0.5 → 4.0.7, no Ruby-major risks apply).

## Critique

### Round 1 (codex exec -p terra)

- Step 4 claimed a bare `--bundler` would re-lock 4.0.19 under auto-switching; `bundle update --bundler` updates the recorded version, so `_4.0.23_` is redundant for the lock result → fixed (Design decisions and Risks now say the exact version is for determinism and `_4.0.23_` only makes the run use the new Bundler)
- The consumer-impact claims are wrong: the gemspec packages neither `Gemfile.lock` nor `.ruby-version`, and a changed `config/*.yml` reaches consumers only after a versioned release → dismissed: consumers reference this gem from GitHub by git SHA (dependencies skill, "Personal gems"), so a merged `config/*.yml` change reaches them on their next `bundle update rubocop-eirvandelden` with no release; the plan already says the lockfile and `.ruby-version` never reach consumers
- Step 8 told the implementer to fix RuboCop offences in arbitrary production files, beyond the declared file scope → fixed (step 8 now fixes only obsolete or invalid config in the owning `config/*.yml` layer and turns any Ruby-file offence into a `Decision needed:` line)
