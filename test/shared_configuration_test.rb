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
    Rails/IndexBy Rails/IndexWith
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

    RULES_WE_TURN_ON.each do |rule|
      assert_includes [ true, "pending" ], settings.dig(rule, "Enabled"), "#{rule} is not switched on"
    end
  end

  # Rules whose advice we disagree with. Listing them means switching one back on has to be a
  # deliberate edit rather than a side effect of a plugin update.
  RULES_WE_TURN_OFF = %w[Obsession/Rails/ValidationMethodName].freeze

  def test_the_shared_rules_switch_off_the_rules_we_disagree_with
    settings = settings_for(RULES_WE_TURN_OFF)

    RULES_WE_TURN_OFF.each do |rule|
      refute settings.fetch(rule).fetch("Enabled"), "#{rule} is not switched off"
    end
  end

  # rubocop-obsession quietly loads rubocop-rspec whenever it can, which would switch on 115
  # RSpec rules in projects that use Minitest. Which rules apply must not depend on that.
  def test_rspec_rules_stay_off_until_a_project_asks_for_them
    refute rspec_rules_switched_on_by("config/default.yml")
  end

  def test_projects_using_rspec_switch_its_rules_on
    assert rspec_rules_switched_on_by("config/rspec.yml")
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
