require_relative "module_self_colon_form"

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Flags a colon after an annotation keyword like `KeywordSeparator`, but accepts a valid
        # `# @rbs module-self: Type`.
        class KeywordSeparatorAllowingColon < KeywordSeparator
          include ModuleSelfColonForm

          private
            # @rbs comment: Parser::Source::Comment
            def valid_method_annotation?(comment) #: bool
              module_self_colon_form?(comment.text) || super
            end
        end
      end
    end
  end
end
