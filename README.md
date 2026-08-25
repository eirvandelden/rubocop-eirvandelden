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

Then inherit the rules in `.rubocop.yml`:

```yaml
inherit_gem:
  rubocop-eirvandelden: config/default.yml
```

Projects with their own `.rubocop_todo.yml` keep it:

```yaml
inherit_gem:
  rubocop-eirvandelden: config/default.yml

inherit_from:
  - .rubocop_todo.yml
```

## What you get

`config/default.yml` builds on `rubocop-rails-omakase` and adds the plugins that suit any
Ruby project — Minitest, Obsession, Packaging, Performance, Rails and YARD. They come with
the gem, so nothing extra goes in a project's Gemfile.

Omakase switches most Performance and Rails cops off. Every rule turned back on is listed
explicitly in `config/default.yml`, and a test asserts each one is still active.

## Projects using RSpec or Capybara

`rubocop-obsession` loads `rubocop-rspec` whenever it is installed, which would switch on 115
RSpec rules in a Minitest project. To stop which rules apply from depending on that, the gem
always bundles `rubocop-rspec` and `config/default.yml` switches the department off. Projects
that actually use RSpec switch it back on:

```yaml
inherit_gem:
  rubocop-eirvandelden: config/rspec.yml
```

Capybara is not bundled, because almost nothing here uses it. Add the gem and inherit its
config:

```ruby
gem "rubocop-capybara", require: false
```

```yaml
inherit_gem:
  rubocop-eirvandelden: config/capybara.yml
```

Both configs already include everything in `config/default.yml`.

## Loose Ruby files

`~/.rubocop.yml` inherits this gem too, which covers scripts that live outside any project.
That needs the gem installed for the global Ruby, not just bundled in a project:

```bash
gem install --local rubocop-eirvandelden
```

## Changing a rule

Edit `config/default.yml`, run `bundle exec rake test`, and open a pull request. Every
project picks the change up on its next `bundle update rubocop-eirvandelden`.
