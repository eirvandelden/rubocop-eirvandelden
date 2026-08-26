# rubocop-eirvandelden

The RuboCop rules every personal Ruby project inherits, so a rule changes in one place
instead of in every repository.

## Why this gem exists

RuboCop stops at the first `.rubocop.yml` it finds walking up from the file being inspected.
Every project has one, so `~/.rubocop.yml` was never opened and the plugins it listed never
loaded. Shipping the rules as a gem puts them somewhere every project — and CI — can reach.

## Use it

Add the gem to the project's development group:

```ruby
gem "rubocop-eirvandelden", github: "eirvandelden/rubocop-eirvandelden", require: false
```

Then name the layers that apply in `.rubocop.yml` — see the table below:

```yaml
inherit_gem:
  rubocop-eirvandelden:
    - config/default.yml
    - config/rails.yml
```

## What you get

`config/default.yml` builds on `rubocop-rails-omakase` and adds the plugins that suit any Ruby
project — Minitest, Obsession, Packaging, Performance and YARD. They come with the gem, so
nothing extra goes in a project's Gemfile.

Omakase switches most Performance cops off, and leaves `Layout/LineLength` off entirely. Every
rule turned back on is listed explicitly, and a test asserts each one is still active.

## Stack a layer for what the project actually is

The configs are layers, not alternatives. List the ones that apply, `default.yml` first:

```yaml
inherit_gem:
  rubocop-eirvandelden:
    - config/default.yml
    - config/rails.yml
```

| Layer | Add it when |
|---|---|
| `config/default.yml` | always |
| `config/rails.yml` | the project is a Rails app or engine |
| `config/rspec.yml` | the tests are specs |
| `config/capybara.yml` | the tests drive a browser |

A plain Ruby project takes `default.yml` alone.

### Why Rails advice is a separate layer

`Rails/AssertNot` and `Rails/RefuteMethods` ask for `assert_not`; `Rails/IndexBy` and
`Rails/IndexWith` ask for `index_by` and `index_with`. All four come from ActiveSupport. A plain
Ruby project has none of them, so those cops do not merely give irrelevant advice — autocorrect
rewrites working code into a method that cannot run, and the lint passes while the tests break.
The ten `Obsession/Rails` cops are Rails-domain advice for the same reason.

RuboCop cannot tell what kind of project it is in. Paths are no help either, because a plain
Ruby `test/` directory looks exactly like a Rails one. So the split has to be declared.

**The layers stack, they do not inherit.** If `capybara.yml` inherited `default.yml`, listing it
after `rails.yml` would re-apply the Rails switch-off and silently undo the Rails layer. A test
covers that.

### Projects using RSpec

`rubocop-obsession` loads `rubocop-rspec` whenever it is installed, which would switch on 115
RSpec rules in a Minitest project. To stop which rules apply from depending on that, the gem
always bundles `rubocop-rspec` and `config/default.yml` switches the department off.
`config/rspec.yml` switches it back on.

Capybara is not bundled, because almost nothing here uses it — add `rubocop-capybara` to the
project alongside the layer.

## Loose Ruby files

`~/.rubocop.yml` inherits this gem too, which covers scripts that live outside any project.
That needs the gem installed for the global Ruby, not just bundled in a project:

```bash
rake install
```

## Changing a rule

Edit `config/default.yml`, run `bundle exec rake test`, and open a pull request. Every
project picks the change up on its next `bundle update rubocop-eirvandelden`.
