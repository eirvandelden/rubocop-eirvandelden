require_relative "module_self_colon_form"

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks inline RBS types like `InvalidTypes`, but accepts a valid `# @rbs module-self: Type`.
        class InvalidTypesAllowingColon < InvalidTypes
          include ModuleSelfColonForm

          private
            # @rbs annotation: RBS::Inline::AST::Annotations::t
            def invalid_annotation?(annotation) #: bool
              return false if colon_form_module_self?(annotation)

              super
            end

            # @rbs annotation: RBS::Inline::AST::Annotations::t
            def colon_form_module_self?(annotation) #: bool
              annotation.is_a?(RBS::Inline::AST::Annotations::ModuleSelf) &&
                annotation.source.comments.any? { |comment| module_self_colon_form?(comment.slice) }
            end
        end
      end
    end
  end
end
