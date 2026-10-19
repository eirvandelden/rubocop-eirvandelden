# Intent: Update all dependencies

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous

## Problem

The gem's lockfile, Ruby version and Bundler version lag behind the latest releases. `rubocop-capybara` is at 3.0.0 (3.1.0 exists) and `uri` is at 1.1.1 (1.1.2 exists). `.ruby-version` is 4.0.5 and Bundler is 4.0.19, while Ruby 4.0.7 is installed and Bundler 4.0.23 is out. Consumers who run `bundle update rubocop-eirvandelden` get cop gems resolved against an untested newer set.

## Proposed outcome

The lockfile, `.ruby-version` and the Bundler version are current, and the test suite and linters pass against them.

## Affected users and systems

- This gem's own development and CI.
- Personal projects that inherit this gem: the cop gems it bundles may behave differently after their next `bundle update rubocop-eirvandelden`.

## Constraints

- Etienne explicitly asked for `bundle update` of all gems (playbook rule 11).
- Approved permission (rule 8): install Bundler 4.0.23 with `gem install bundler`. No other system tool is installed, upgraded or switched.
- Approved: bump `.ruby-version` from 4.0.5 to 4.0.7. Ruby 4.0.7 is already installed via `rv`.
- Gemspec `required_ruby_version` stays `>= 3.4`.
- No gem is added or removed.
- If an update breaks `test/shared_configuration_test.rb`, fix `config/*.yml` so the tests pass. Never edit the test to pass. Stop and ask Etienne if the fix changes which cops are on or off.

## In scope

- `bundle update` for every gem, so `Gemfile.lock` holds the latest allowed versions.
- `bundle update --bundler`, so `BUNDLED WITH` becomes 4.0.23.
- `.ruby-version` set to 4.0.7.
- Config changes in `config/*.yml` that a new cop version forces, such as a renamed cop, within the constraint above.
- A `CHANGELOG.md` entry if the changelog records dependency or config changes.

## Out of scope

- Adding or removing dependencies.
- Changing gemspec version constraints or `required_ruby_version`.
- Changing `.github/workflows/ci.yml`.
- Enabling or disabling cops for new-cop reasons that the update does not force.
- Releasing a new gem version.

## Acceptance criteria

- `Gemfile.lock` lists `rubocop-capybara` 3.1.0 and `uri` 1.1.2, and `bundle outdated` reports nothing.
- `Gemfile.lock` records `BUNDLED WITH 4.0.23`.
- `.ruby-version` reads `4.0.7`.
- `rake test` passes with the updated gems.
- RuboCop passes on this repository with the updated gems.
- Bundler Audit reports no vulnerabilities, if the repository uses it.

## Open questions

None.
