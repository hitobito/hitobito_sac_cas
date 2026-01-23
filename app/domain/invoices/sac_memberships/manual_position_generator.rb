# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class ManualPositionGenerator < PositionGenerator
      attr_reader :manual_positions

      def initialize(member, manual_positions)
        @member = member
        @manual_positions = manual_positions
      end

      def generate(memberships, new_entry: false)
        positions = super

        positions.map do |position|
          position.amount = manual_position_amount(position)
          position
        end
      end

      private

      def new_entry_positions(main_membership, new_entry)
        build_positions(new_entry_positions_to_transmit, main_membership)
      end

      def manual_position_amount(position)
        if SECTION_POSITIONS.any? { position.is_a?(_1) }
          manual_section_position_amount(position)
        else
          manual_positions[position_name(position).to_sym].to_f
        end
      end

      def manual_section_position_amount(position)
        manual_positions[position_name(position).pluralize.to_sym]&.find do |manual_position|
          manual_position[:section_id] == position.section.id
        end&.dig(:fee).to_f
      end

      def new_entry_positions_to_transmit
        NEW_ENTRY_POSITIONS.select do |position_class|
          manual_positions[position_class.name.demodulize.underscore.to_sym].present?
        end
      end

      def position_name(position)
        position.class.name.demodulize.underscore
      end
    end
  end
end
