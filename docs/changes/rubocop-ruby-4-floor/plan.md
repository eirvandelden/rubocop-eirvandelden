# Plan: Require a RuboCop that knows Ruby 4.0

From `intent.md` (2026-11-06). Status: accepted.

## Design

### Domain terms

- **RuboCop floor** — the lowest RuboCop release that the gemspec accepts. After this change it is 1.92.0. New term.
- **Accepted set** — the candidate RuboCop versions that satisfy the gemspec's `rubocop` requirement, as `Gem::Requirement#satisfied_by?` computes it offline. New term.
- **Fresh resolve** — Bundler resolves a project's gems with no lockfile, as appkit CI does. New term.

### Diagrams

Not affected: the change adds no class, object or message. It changes one gemspec requirement.

### Signatures

Not affected: the change adds no public method. The gemspec line becomes `spec.add_dependency "rubocop", "~> 1.92"`. The new test method is in a test file, which the shared rules exempt from signatures.

### Complexity

Not affected: there is no runtime path and no query. The new test loads the gemspec once and runs six `satisfied_by?` checks, with no network, no Bundler resolve and no subprocess.

### Invariants

- The `rubocop` requirement in `rubocop-eirvandelden.gemspec` accepts 1.92.0, 1.92.1 and any later 1.x. It refuses 1.74, 1.91 and 2.0. The gemspec enforces it; `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` proves it.
- The PATH section of `Gemfile.lock` carries the same requirement as the gemspec. Bundler enforces it in frozen mode: `BUNDLE_FROZEN=true bundle exec rake test` fails when the two differ.

### Alternatives

1. **Behaviour test over an accepted set (chosen).** The test lists six candidate versions and asserts which of them the requirement accepts. Each acceptance criterion maps to a visible version in the test. A floor too low, a floor too high and a missing ceiling each change the set.
2. **Requirement-equality test (rejected).** `assert_equal Gem::Requirement.new("~> 1.92"), rubocop.requirement`, the idiom of the existing rbs_inline test. It is shorter, but it proves the criteria only through the reader's knowledge of `~>`. The intent's criteria name versions, so the test names versions.
3. **Test tied to `RuboCop::TargetRuby::KNOWN_RUBIES` (rejected).** The loaded constant comes from the locked 1.92.1, not from the floor, so the test passes whatever the floor is. Checking the floor itself needs RuboCop 1.92.0 installed or fetched over the network.

A real Bundler resolve in the test was also rejected: it needs the network or a local gem index, and it is slow. Bundler applies `Gem::Requirement` as written, so the offline check proves the same rule.

## Design decisions

- The constraint is `~> 1.92`, as `intent.md`'s `## Decisions` records. No conflict with intent.
- The constraint is one argument `"~> 1.92"`, not `">= 1.92", "< 2"`. The `dependencies` skill prescribes `~> major.minor`, and the two forms are equivalent.
- `Gemfile.lock` changes too, although the intent's In scope list does not name it. Its PATH section mirrors the gemspec's dependencies; without the update a frozen install fails, and the next `bi` anywhere rewrites it as an unrelated diff. The GEM section keeps RuboCop 1.92.1, which satisfies the new constraint. This is a consequence of the in-scope gemspec change, not new scope.
- The changelog line goes in the existing `## 1.0.0` section, after the Ruby 4.0 line, as the intent says.

## Integration points

- Bundler and RubyGems: every consuming project's resolve reads the new requirement.
- Consuming projects locked to RuboCop 1.82–1.91 must run `bundle update rubocop` together with `bundle update rubocop-eirvandelden`.
- This repository's CI (`.github/workflows/ci.yml`) installs from `Gemfile.lock` through `setup-rv` with `install-gems: true`. The workflow does not set frozen mode, so parity is proven locally with `BUNDLE_FROZEN=true`.

## Files that change

- `test/shared_configuration_test.rb` — add `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` after `test_the_gem_asks_for_an_rbs_inline_plugin_that_knows_every_named_cop` (around line 236).
- `rubocop-eirvandelden.gemspec` — line 16 becomes `spec.add_dependency "rubocop", "~> 1.92"`.
- `Gemfile.lock` — PATH section line 5 becomes `rubocop (~> 1.92)`. Regenerate with `bi`; never edit by hand.
- `CHANGELOG.md` — one line in `## 1.0.0`, after "Requires Ruby 4.0 or newer (was 3.4).": `- Requires RuboCop 1.92 or a later 1.x (was any version). RuboCop 1.82 is the first release that knows Ruby 4.0, and 1.92 is the release this gem's CI tests.`

The test to add:

```ruby
  # RuboCop 1.82 is the first release that knows Ruby 4.0. The gem's floor is 1.92, so a fresh
  # resolve never falls back to a RuboCop that rejects TargetRubyVersion 4.0.
  def test_the_gem_accepts_rubocop_1_92_or_a_later_1_x
    specification = Gem::Specification.load("rubocop-eirvandelden.gemspec")
    rubocop = specification.dependencies.find { |dependency| dependency.name == "rubocop" }
    accepted = %w[1.74 1.91 1.92.0 1.92.1 1.99 2.0].select do |version|
      rubocop.requirement.satisfied_by?(Gem::Version.new(version))
    end

    assert_equal %w[1.92.0 1.92.1 1.99], accepted
  end
```

## Order of work

1. Add the test above. Run `bundle exec ruby -Itest test/shared_configuration_test.rb -n test_the_gem_accepts_rubocop_1_92_or_a_later_1_x`. Watch it fail: the unconstrained requirement accepts all six versions, so `accepted` also holds `1.74`, `1.91` and `2.0`.
2. Commit the failing test on its own (bug fix: the regression test comes first).
3. Change the gemspec's `rubocop` line to `"~> 1.92"`.
4. Run `bi`. Confirm with `git diff Gemfile.lock` that only the PATH line `rubocop` → `rubocop (~> 1.92)` changes and the GEM section still holds `rubocop (1.92.1)`.
5. Run the single test again. Watch it pass.
6. Commit the gemspec and `Gemfile.lock` together.
7. Add the `CHANGELOG.md` line. Commit it on its own.
8. Run the full suite in frozen mode: `BUNDLE_FROZEN=true bundle exec rake test`. Run the linter: `bundle exec rubocop`. Both must be green.
9. Re-read the full diff against `main`. Every hunk must be one of the four files above.

## Risks

- **Projects locked to RuboCop 1.82–1.91 fail to resolve** when they update this gem alone. Accepted by the intent; the changelog line tells them to update RuboCop too.
- **A consumer whose other gems cap RuboCop below 1.92** now gets a Bundler conflict instead of a silent fallback. This is the intended outcome.
- **`bi` changes more than the PATH line** (for example, it re-resolves other gems). Step 4 checks the diff; anything beyond the PATH line is reverted and reported, not committed.
- **The test proves the requirement, not a real Bundler resolve.** Bundler applies `Gem::Requirement` as written, so the behaviour is the same. A live resolve was rejected as slow and network-bound.
- Out of scope, and untouched: floors on the other bundled cop gems, the appkit fix in `rakelib/signatures.rake:12`, the gem version number, `~/.rubocop.yml` in dotfiles (no cop rule changes), and `GLOSSARY.md`.

## Proof

- A project cannot resolve this gem next to RuboCop 1.74, nor next to 1.91 → `test/shared_configuration_test.rb` `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` (1.74 and 1.91 are absent from the accepted set).
- RuboCop 1.92.0, the locked 1.92.1 and any later 1.x satisfy the gemspec; RuboCop 2.0 does not → `test/shared_configuration_test.rb` `test_the_gem_accepts_rubocop_1_92_or_a_later_1_x` (1.92.0, 1.92.1 and 1.99 are in the set; 2.0 is not).
- The changelog tells consumers that the gem now needs RuboCop 1.92 or newer → check: `grep -n "RuboCop 1.92 or a later 1.x" CHANGELOG.md` prints one line inside the `## 1.0.0` section. The wording names the 1.x ceiling, because `~> 1.92` refuses RuboCop 2.0.
- Invariant: the `Gemfile.lock` PATH section matches the gemspec, enforced by Bundler in frozen mode → check: `BUNDLE_FROZEN=true bundle exec rake test` runs without a lockfile error, and `git diff main -- Gemfile.lock` shows only `rubocop (~> 1.92)` under PATH.

Per changed file, the unit tests expected, named as behaviour:
- `rubocop-eirvandelden.gemspec`: `the gem accepts RuboCop 1.92 or a later 1.x`.
- `Gemfile.lock`, `CHANGELOG.md`: none (configuration and documentation; checked above).

Test setup: none. The test loads the real gemspec from the repository root, as the existing gemspec tests do. No fixtures, no network, no faked boundaries.

---
Domain skills applied: dependencies (constraint style, approval already recorded in intent), rails-testing (Minitest idiom of the existing suite), software-design (alternatives). Rails architecture, API design and UI do not apply.

## Critique

### Round 1 (codex exec -p terra)

- The changelog line says "RuboCop 1.92 or newer", but `~> 1.92` refuses RuboCop 2.0, which the test also requires → fixed (changelog line and its Proof check now say "RuboCop 1.92 or a later 1.x")
- The plan claims a frozen CI install enforces lockfile parity, but `.github/workflows/ci.yml` only sets `install-gems: true` and never configures frozen mode → fixed (CI claim removed; Invariants, Integration points, Order of work step 8 and Proof now use `BUNDLE_FROZEN=true bundle exec rake test`)

Reproduction: committed
