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
  ].freeze

  MALFORMED_WITHOUT_MAGIC_COMMENT = <<~RUBY.freeze
    # @rbs name: Array[String
    def greet(name)
      name
    end
  RUBY

  def test_a_malformed_inline_rbs_annotation_fails_lint_without_a_magic_comment
    output, status = lint(MALFORMED_WITHOUT_MAGIC_COMMENT)

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/InvalidTypes"
  end

  def test_a_public_method_without_a_signature_fails_lint
    output, status = lint("def greet(name)\n  name\nend\n")

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingTypeAnnotation"
  end

  def test_a_public_method_with_a_signature_above_it_passes_lint
    output, status = lint("#: (String) -> String\ndef greet(name)\n  name\nend\n")

    assert_predicate status, :success?, output
  end

  PRIVATE_METHOD = <<~RUBY.freeze
    class Greeter
      private
        def greet(name)
          name
        end
    end
  RUBY

  def test_a_private_method_without_a_signature_passes_lint
    output, status = lint(PRIVATE_METHOD)

    assert_predicate status, :success?, output
  end

  def test_a_public_attribute_without_a_type_fails_lint
    output, status = lint("class Greeter\n  attr_reader :name\nend\n")

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingTypeAnnotation"
  end

  def test_a_public_attribute_with_a_trailing_type_passes_lint
    output, status = lint("class Greeter\n  attr_reader :name #: String\nend\n")

    assert_predicate status, :success?, output
  end

  UNTYPED_DATA = "Point = Data.define(:x, :y)\n".freeze

  TYPED_DATA = <<~RUBY.freeze
    Point = Data.define(
      :x,  #: Integer
      :y   #: Integer
    )
  RUBY

  def test_a_data_class_fails_lint_until_each_attribute_has_a_type
    output, status = lint(UNTYPED_DATA)
    typed_output, typed_status = lint(TYPED_DATA)

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingDataClassAnnotation"
    assert_predicate typed_status, :success?, typed_output
  end

  UNTYPED_STRUCT = "Point = Struct.new(:x, :y)\n".freeze

  TYPED_STRUCT = <<~RUBY.freeze
    Point = Struct.new(
      :x,  #: Integer
      :y   #: Integer
    )
  RUBY

  def test_a_struct_class_fails_lint_until_each_attribute_has_a_type
    output, status = lint(UNTYPED_STRUCT)
    typed_output, typed_status = lint(TYPED_STRUCT)

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingStructClassAnnotation"
    assert_predicate typed_status, :success?, typed_output
  end

  OPTED_OUT = <<~RUBY.freeze
    # rbs_inline: disabled

    # @rbs name: Array[String
    def greet(name)
      name
    end
  RUBY

  def test_a_file_that_opts_out_passes_lint_however_it_is_annotated
    output, status = lint(OPTED_OUT)

    assert_predicate status, :success?, output
  end

  LEFTOVER_MAGIC_COMMENT = <<~RUBY.freeze
    # rbs_inline: enabled

    #: (String) -> String
    def greet(name)
      name
    end
  RUBY

  def test_a_leftover_rbs_inline_magic_comment_fails_lint
    output, status = lint(LEFTOVER_MAGIC_COMMENT)

    refute_predicate status, :success?
    assert_includes output, "Remove # rbs_inline: magic comment."
  end

  def test_autocorrect_removes_a_leftover_rbs_inline_magic_comment
    corrected = autocorrect(LEFTOVER_MAGIC_COMMENT)

    refute_includes corrected, "# rbs_inline:"
    assert_includes corrected, "#: (String) -> String\ndef greet(name)"
  end

  def test_a_method_marked_rbs_skip_passes_lint_without_a_signature
    output, status = lint("# @rbs skip\ndef greet(name)\n  name\nend\n")

    assert_predicate status, :success?, output
  end

  def test_an_unannotated_public_method_in_a_test_or_spec_passes_lint
    [ "test/greeter_test.rb", "spec/greeter_spec.rb" ].each do |path|
      output, status = lint("def greet(name)\n  name\nend\n", path: path)

      assert_predicate status, :success?, "#{path}: #{output}"
    end
  end

  MIGRATION = <<~RUBY.freeze
    class CreateGreetings < ActiveRecord::Migration[8.0]
      def change
        create_table :greetings
      end
    end
  RUBY

  def test_a_rails_project_does_not_demand_a_signature_on_a_migration
    output, status = lint(MIGRATION, "test/fixtures/rails_project.yml",
                          path: "db/migrate/20260101000000_create_greetings.rb")

    assert_predicate status, :success?, output
  end

  def test_the_shared_rules_demand_a_signature_on_a_migration_outside_rails
    output, status = lint(MIGRATION, path: "db/migrate/20260101000000_create_greetings.rb")

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingTypeAnnotation"
  end

  CONTROLLER = <<~RUBY.freeze
    class GreetingsController < ApplicationController
      def index
        head :ok
      end
    end
  RUBY

  def test_a_rails_project_demands_a_signature_on_a_controller_action
    output, status = lint(CONTROLLER, "test/fixtures/rails_project.yml",
                          path: "app/controllers/greetings_controller.rb")

    refute_predicate status, :success?
    assert_includes output, "Style/RbsInline/MissingTypeAnnotation"
  end

  def test_a_rails_project_does_not_demand_a_signature_in_a_test
    output, status = lint("def greet(name)\n  name\nend\n", "test/fixtures/rails_project.yml",
                          path: "test/greeter_test.rb")

    assert_predicate status, :success?, output
  end

  def test_autocorrect_keeps_a_colon_signature_and_drops_rbs_lines_beside_it
    signed = "#: (String) -> String\ndef greet(name)\n  name\nend\n"
    corrected = autocorrect("# @rbs name: String\n# @rbs return: String\n#{signed}")

    assert_equal signed, corrected
  end

  def test_the_gem_reports_version_one
    specification = Gem::Specification.load("rubocop-eirvandelden.gemspec")

    assert_equal Gem::Version.new("1.0.0"), specification.version
  end

  def test_the_gem_asks_for_an_rbs_inline_plugin_that_knows_every_named_cop
    specification = Gem::Specification.load("rubocop-eirvandelden.gemspec")
    plugin = specification.dependencies.find { |dependency| dependency.name == "rubocop-rbs_inline" }

    assert_equal Gem::Requirement.new("~> 2.0"), plugin.requirement
  end

  WRONG_YARD_TAG_TYPE = <<~RUBY.freeze
    # @param name [Array<String]
    #: (Array[String]) -> Array[String]
    def greet(name)
      name
    end
  RUBY

  INLINE_RBS_RULES = %w[
    DataClassCommentAlignment DataDefineWithBlock EmbeddedRbsSpacing InvalidComment InvalidTypes
    KeywordSeparator MethodCommentSpacing MissingDataClassAnnotation MissingStructClassAnnotation
    MissingTypeAnnotation ParametersSeparator RedundantAnnotationWithSkip
    RedundantInstanceVariableAnnotation RedundantTypeAnnotation RequireRbsInlineComment
    StructClassCommentAlignment StructNewWithBlock UnmatchedAnnotations VariableCommentSpacing
  ].map { |rule| "Style/RbsInline/#{rule}" }.freeze

  def test_a_yard_comment_with_a_wrong_tag_type_passes_lint_under_the_shared_rules
    output, status = lint(WRONG_YARD_TAG_TYPE)

    assert_predicate status, :success?, output
  end

  def test_a_project_that_switches_yard_on_gets_the_yard_cops_back
    output, status = lint(WRONG_YARD_TAG_TYPE, "test/fixtures/project_using_yard.yml")

    refute_predicate status, :success?
    assert_includes output, "YARD/TagTypeSyntax"
  end

  def test_the_shared_rules_switch_on_every_inline_rbs_rule
    settings = settings_for(INLINE_RBS_RULES)
    switched_off = INLINE_RBS_RULES.reject { |rule| settings.fetch(rule).fetch("Enabled") == true }

    assert_empty switched_off
  end

  def test_the_shared_rules_accept_inline_rbs_annotations_without_a_space
    setting = settings_for([ "Layout/LeadingCommentSpace" ]).fetch("Layout/LeadingCommentSpace")

    assert setting.fetch("AllowRBSInlineAnnotation")
  end

  def test_yard_rules_stay_off_until_a_project_asks_for_them
    off_by_default = settings_for([ "YARD/TagTypeSyntax" ]).fetch("YARD/TagTypeSyntax").fetch("Enabled")
    on_when_asked = settings_for([ "YARD/TagTypeSyntax" ], "test/fixtures/project_using_yard.yml")
      .fetch("YARD/TagTypeSyntax").fetch("Enabled")

    assert_equal [ false, true ], [ off_by_default, on_when_asked ]
  end

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

  # Not under Capybara/RSpec/, so it applies whichever test framework the project's system tests use.
  FRAMEWORK_NEUTRAL_CAPYBARA_RULE = "Capybara/SpecificFinders".freeze

  def test_a_rails_project_using_capybara_keeps_both_sets_of_advice
    settings = settings_for(RAILS_RULES + [ FRAMEWORK_NEUTRAL_CAPYBARA_RULE ],
                            "test/fixtures/rails_project_using_capybara.yml")
    switched_off = settings.reject { |_rule, setting| setting.fetch("Enabled") == true }.keys

    assert_empty switched_off
  end

  def test_a_rule_rubocop_does_not_recognise_fails_with_rubocops_own_message
    failure = assert_raises(Minitest::Assertion) do
      settings_for([ "Capybara/NoSuchRule" ], "test/fixtures/rails_project_using_capybara.yml")
    end

    assert_includes failure.message, "Unrecognized cop: Capybara/NoSuchRule"
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
    def lint(source, configuration = "config/default.yml", path: "lib/example.rb")
      output, status = Open3.capture2e("bundle", "exec", "rubocop", "--stdin", path,
                                       "-c", configuration, "--format", "simple", stdin_data: source)

      [ output.force_encoding(Encoding::UTF_8), status ]
    end

    # `--autocorrect-all` because RedundantTypeAnnotation is not a safe autocorrect. `--stderr`
    # keeps the report off stdout, which then holds only the corrected source.
    def autocorrect(source, configuration = "config/default.yml", path: "lib/example.rb")
      corrected, = Open3.capture3("bundle", "exec", "rubocop", "--stdin", path, "-c", configuration,
                                  "--autocorrect-all", "--stderr", "--format", "quiet", stdin_data: source)

      corrected.force_encoding(Encoding::UTF_8)
    end

    def settings_for(rules, configuration = "config/default.yml")
      output, status = run_rubocop(configuration, rules.join(","))

      assert_predicate status, :success?, complaints_in(output)

      YAML.safe_load(output, aliases: true)
    end

    # A runner without a UTF-8 locale hands back output tagged US-ASCII, which breaks on the
    # accented characters in RuboCop's cop descriptions.
    def run_rubocop(configuration, rules = nil)
      output, status = Open3.capture2e("bundle", "exec", "rubocop", "--show-cops", *rules,
                                       "-c", configuration)

      [ output.force_encoding(Encoding::UTF_8), status ]
    end

    def complaints_in(output)
      complaints = output.lines.grep(/\A(Unrecognized cop|Did you mean\?|Error:)/)

      complaints.empty? ? output : complaints.join
    end

    def departments_offered_by(configuration)
      output, _ = run_rubocop(configuration)

      output.scan(/^([A-Z][A-Za-z]*)\/[A-Za-z]/).flatten.uniq
    end

    def rspec_rules_switched_on_by(configuration)
      settings_for([ "RSpec/ExpectChange" ], configuration)
        .fetch("RSpec/ExpectChange").fetch("Enabled")
    end
end
