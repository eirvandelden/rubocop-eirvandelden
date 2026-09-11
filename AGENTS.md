# rubocop-eirvandelden

## What this is

A RuboCop configuration gem: the shared lint rules for Etienne's personal Ruby projects, packaged so a project pulls them in with `inherit_gem` instead of each repo carrying its own copy of the rules. It builds on `rubocop-rails-omakase` and bundles the cop gems it needs (rubocop-rails, rubocop-minitest, rubocop-rspec, rubocop-obsession, rubocop-packaging, rubocop-performance, rubocop-yard) so a consuming project adds nothing extra to its own Gemfile.

## Domain

The gem ships four config layers under `config/`: `default.yml` (always, the base every project inherits), `rails.yml` (Rails apps/engines), `rspec.yml` (projects whose tests are RSpec specs), `capybara.yml` (projects whose tests drive a browser — also needs `rubocop-capybara` added by the consumer). Layers stack, they do not inherit from each other: a consumer lists every layer it needs in its own `.rubocop.yml`, `default.yml` first. `default.yml` switches the `RSpec` and `Rails`/`Obsession/Rails` departments off; `rspec.yml` and `rails.yml` switch the relevant one back on. `test/shared_configuration_test.rb` asserts the layering behaves this way and that every cop the README claims is on actually is.

## Commands

- `bundle install` — install dependencies.
- `bundle exec rake test` (or plain `rake`, it's the default task) — run `test/shared_configuration_test.rb`.
- `rake install` — install the gem for the global Ruby, so `~/.rubocop.yml` (which inherits this gem) can lint files outside any project.

## Gotchas

- Changing a cop's setting only in `config/default.yml` is not enough if the cop belongs to a domain-specific layer (Rails, RSpec, Capybara) — check which layer actually owns it.
- Never let `rails.yml` or `capybara.yml` `inherit_from` `default.yml`; that would double-apply `default.yml`'s department switch-offs when a consumer lists both, silently undoing the layer. A test guards this, but don't reintroduce it.
- Rails-flavored cops (`Rails/AssertNot`, `Rails/IndexBy`, `Rails/IndexWith`, the `Obsession/Rails` cops) autocorrect into ActiveSupport methods that don't exist in a plain Ruby project — that's why they live in `rails.yml`, not `default.yml`.
- A rule change here doesn't reach a consuming project until that project runs `bundle update rubocop-eirvandelden`.
