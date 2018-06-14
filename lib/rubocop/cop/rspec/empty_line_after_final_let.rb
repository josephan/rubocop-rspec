# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after the last let block.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #   let(:something) { other }
      #   it { does_something }
      #
      #   # good
      #   let(:foo) { bar }
      #   let(:something) { other }
      #
      #   it { does_something }
      class EmptyLineAfterFinalLet < Cop
        include RangeHelp
        include RuboCop::RSpec::FinalEndLocation

        MSG = 'Add an empty line after the last `let` block.'.freeze

        def_node_matcher :let?, Helpers::ALL.block_pattern

        def on_block(node)
          return unless example_group_with_body?(node)

          latest_let = node.body.child_nodes.select { |child| let?(child) }.last

          return if latest_let.nil?
          return if latest_let.equal?(node.body.children.last)

          no_new_line_after(latest_let) do |location|
            add_offense(latest_let, location: location)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            no_new_line_after(node) do |location|
              corrector.insert_after(location.end, "\n")
            end
          end
        end

        private

        def no_new_line_after(node)
          line = final_end_location(node).line
          line += 1 while comment_line?(processed_source[line])

          return if processed_source[line].blank?
          yield offending_loc(node, line)
        end

        def offending_loc(node, last_line)
          offending_line = processed_source[last_line - 1]
          if comment_line?(offending_line)
            start = offending_line.index('#')
            length = offending_line.length - start
            source_range(processed_source.buffer, last_line, start, length)
          else
            node.loc.expression
          end
        end
      end
    end
  end
end
