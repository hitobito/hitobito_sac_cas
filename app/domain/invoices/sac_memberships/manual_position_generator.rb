# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class ManualPositionGenerator < PositionGenerator
      attr_reader :manual_positions

      def initialize(member)
        @member = member
        @manual_positions = manual_positions
      end

      def generate(memberships, new_entry: false)
        positions = super

        positions.map do |position|
          position.amount = manual_position_amount(position)
        end
      end

      private

      def manual_position_amount(position)
        manual_positions[position.class.name.demodulize.underscore.to_sym].tap do |position_amount|
          if SECTION_POSITIONS.any? { position.is_a?(_1) }
            position_amount.find { position.section }[:fee]
          end
        end
      end
    end
  end
end
