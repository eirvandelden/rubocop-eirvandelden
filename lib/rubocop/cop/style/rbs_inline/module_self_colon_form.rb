require "rubocop-rbs_inline"

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Recognises `# @rbs module-self: Type`, the form RBS 4's inline parser (and so Steep)
        # requires, where rbs-inline 0.14 reads `# @rbs module-self Type`.
        module ModuleSelfColonForm
          COLON_FORM = /\A#\s*@rbs\s+module-self:\s*(?<type>.+?)(?:\s+--.*)?\z/ #: Regexp

          private
            # @rbs text: String
            def module_self_colon_form?(text) #: bool
              type = COLON_FORM.match(text.strip)&.[](:type) or return false

              !RBS::Parser.parse_type(type, require_eof: true).nil?
            rescue RBS::ParsingError
              false
            end
        end
      end
    end
  end
end
