require "minitest/autorun"
require "open3"
require "yaml"

# Every project inherits these files. If a plugin listed inside one is missing from the
# gem's dependencies, RuboCop aborts rather than warns -- which is how the shared rules
# silently stopped applying in the first place. These tests fail loudly instead.
class SharedConfigurationTest < Minitest::Test
  CORE_DEPARTMENTS = %w[Minitest Obsession Packaging Performance Rails YARD].freeze

  # Omakase switches most of these off. Every one is turned back on deliberately, so a rule
  # quietly reverting to omakase's default has to break a test.
  RULES_WE_TURN_ON = %w[
    Minitest/UnreachableAssertion
    Performance/BindCall Performance/DeletePrefix Performance/DeleteSuffix Performance/EndWith
    Performance/FlatMap Performance/MapCompact Performance/RedundantMerge Performance/RegexpMatch
    Performance/ReverseEach Performance/SelectMap Performance/StartWith
    Performance/StringReplacement Performance/UnfreezeString
    Layout/LineLength Metrics/BlockLength Style/FrozenStringLiteralComment
    YARD/CollectionStyle YARD/CollectionType YARD/MeaninglessTag YARD/MismatchName
    YARD/TagTypeSyntax YARD/TagTypePosition
  ].freeze

  def test_the_shared_rules_load_without_error
    _, status = run_rubocop("config/default.yml")

    assert_predicate status, :success?, "the shared rules could not be loaded"
  end

  def test_the_shared_rules_offer_cops_from_every_bundled_plugin
    departments = departments_offered_by("config/default.yml")

    CORE_DEPARTMENTS.each do |department|
      assert_includes departments, department, "no #{department} cop is available"
    end
  end

  def test_the_shared_rules_switch_on_every_rule_we_chose_over_omakase
    settings = settings_for(RULES_WE_TURN_ON)
    switched_off = RULES_WE_TURN_ON.reject { |rule| settings.fetch(rule).fetch("Enabled") == true }

    assert_empty switched_off
  end

  # Rails advice suggests ActiveSupport methods. A plain Ruby project has none, so these must
  # stay out of the rules every project shares or autocorrect writes a method that cannot run.
  RAILS_RULES = %w[
    Rails/AssertNot Rails/IndexBy Rails/IndexWith Rails/RefuteMethods
    Obsession/Rails/MigrationBelongsTo Obsession/Rails/NoCallbackConditions
    Obsession/Rails/ServiceName Obsession/Rails/ShortValidate
  ].freeze

  def test_rails_advice_stays_out_of_the_rules_every_project_shares
    settings = settings_for(RAILS_RULES)
    still_on = RAILS_RULES.select { |rule| settings.fetch(rule).fetch("Enabled") }

    assert_empty still_on
  end

  def test_rails_projects_get_the_rails_advice
    settings = settings_for(RAILS_RULES, "config/rails.yml")
    switched_off = RAILS_RULES.reject { |rule| settings.fetch(rule).fetch("Enabled") == true }

    assert_empty switched_off
  end

  def test_a_rails_project_using_capybara_keeps_both_sets_of_advice
    settings = settings_for(RAILS_RULES + [ "Capybara/CurrentPathExpectation" ],
                            "test/fixtures/rails_project_using_capybara.yml")
    switched_off = settings.reject { |_rule, setting| setting.fetch("Enabled") == true }.keys

    assert_empty switched_off
  end

  # Rules whose advice we disagree with. Listing them means switching one back on has to be a
  # deliberate edit rather than a side effect of a plugin update.
  RULES_WE_TURN_OFF = %w[Obsession/Rails/ValidationMethodName].freeze

  def test_the_shared_rules_switch_off_the_rules_we_disagree_with
    settings = settings_for(RULES_WE_TURN_OFF)
    still_switched_on = RULES_WE_TURN_OFF.select { |rule| settings.fetch(rule).fetch("Enabled") }

    assert_empty still_switched_on
  end

  # rubocop-obsession quietly loads rubocop-rspec whenever it can, which would switch on 115
  # RSpec rules in projects that use Minitest. Which rules apply must not depend on that.
  def test_rspec_rules_stay_off_until_a_project_asks_for_them
    off_by_default = rspec_rules_switched_on_by("config/default.yml")
    on_when_asked = rspec_rules_switched_on_by("config/rspec.yml")

    assert_equal [ false, true ], [ off_by_default, on_when_asked ]
  end

  # The gem is configuration files, so the Ruby it asks for is a choice rather than a
  # constraint. Ask for too new a one and projects that could happily use these rules cannot
  # install them at all.
  def test_the_gem_asks_for_a_ruby_its_projects_actually_run
    specification = Gem::Specification.load("rubocop-eirvandelden.gemspec")

    assert_equal Gem::Requirement.new(">= 3.4"), specification.required_ruby_version
  end

  # A layer that sets Exclude replaces the list it inherits unless it says otherwise, so an
  # extra layer can quietly re-enable a cop for routes, environments and tests.
  def test_stacking_the_rspec_layer_keeps_what_the_shared_layer_excludes
    settings = settings_for([ "Metrics/BlockLength" ], "test/fixtures/rails_project_using_rspec.yml")
    excluded = settings.fetch("Metrics/BlockLength").fetch("Exclude").map(&:to_s)
    missing = [ "config/environments", "spec" ].reject do |path|
      excluded.any? { |exclusion| exclusion.include?(path) }
    end

    assert_empty missing
  end

  def test_projects_using_capybara_can_add_its_cops
    assert_includes departments_offered_by("config/capybara.yml"), "Capybara"
  end

  private
    # A runner without a UTF-8 locale hands back output tagged US-ASCII, which breaks on the
    # accented characters in RuboCop's cop descriptions.
    def run_rubocop(configuration, rules = nil)
      output, status = Open3.capture2e("bundle", "exec", "rubocop", "--show-cops", *rules,
                                       "-c", configuration)

      [ output.force_encoding(Encoding::UTF_8), status ]
    end

    def departments_offered_by(configuration)
      output, _ = run_rubocop(configuration)

      output.scan(/^([A-Z][A-Za-z]*)\/[A-Za-z]/).flatten.uniq
    end

    def settings_for(rules, configuration = "config/default.yml")
      output, _ = run_rubocop(configuration, rules.join(","))

      YAML.safe_load(output, aliases: true)
    end

    def rspec_rules_switched_on_by(configuration)
      settings_for([ "RSpec/ExpectChange" ], configuration)
        .fetch("RSpec/ExpectChange").fetch("Enabled")
    end
end
