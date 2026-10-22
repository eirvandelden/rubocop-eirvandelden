# Review: update-dependencies

## Round 1 — 2026-10-22 11:31 UTC — f0fe8f6

No `REVIEW.md` or `REVIEW.local.md` exists at the repository root, so this round uses the default Bugs, Security, Compliance and Design passes.

Checks run: `rv run -- ruby -v` prints 4.0.7; `rake test` 21 runs, 0 failures; `rubocop` no offenses; `bundle outdated --strict` up to date (plain lists only prism 2.0.0, as intent records); `bundle-audit check --update` no vulnerabilities; the built gem is refused by Ruby 3.4.11 ("requires Ruby version >= 4.0") and installs on 4.0.7; `actions/checkout` latest release is v7.0.1, as `ci.yml` pins. CI on the pull request is not checked yet: no pull request exists.

Compliance: every intent acceptance criterion has its proof, and the Proof test `test_the_gem_asks_for_a_ruby_its_projects_actually_run` exists with the new expected value. No test is weakened, skipped or deleted.

- [ ] Nit: Commit "Update rubocop to 1.92.1" moves `rubocop` 1.92.0 to 1.92.1, two Gemfile.lock hunks that plan.md's Files that change does not list; it still says "exactly these seven hunks". The bump is in intent's scope; record it in plan.md so the plan matches the branch. — `docs/changes/update-dependencies/plan.md:71` → fixed (Record the rubocop 1.92.1 bump in the plan)

## Round 2 — 2026-10-22 11:33 UTC — 26ad0fa

Still no `REVIEW.md` or `REVIEW.local.md` at the repository root; this round uses the default Bugs, Security, Compliance and Design passes.

Checks run: `rv run -- ruby -v` prints 4.0.7; `rv run -- bundle -v` prints 4.0.23; `rake test` 21 runs, 0 failures; `rubocop` no offenses; `bundle outdated --strict` up to date (plain lists only prism 2.0.0, as intent records); `bundle-audit check --update` no vulnerabilities. Code is unchanged since round 1 (f0fe8f6); only `plan.md` moved.

Round 1 nit holds: `plan.md` Files that change now lists the `rubocop` 1.92.0 → 1.92.1 bump and its checksum, matching commit f0fe8f6, which touches only those two `Gemfile.lock` lines.

Bugs, Security, Compliance, Design: no findings. CI on the pull request is not checked yet: no pull request exists.
