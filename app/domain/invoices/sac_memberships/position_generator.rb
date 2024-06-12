# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class PositionGenerator

      SAC_POSITIONS = [
        Positions::SacFee,
        Positions::HutSolidarityFee,
        Positions::SacMagazine,
        Positions::SacMagazinePostageAbroad
      ].freeze

      SECTION_POSITIONS = [
        Positions::SectionFee,
        Positions::SectionBulletinPostageAbroad
      ].freeze

      NEW_ENTRY_POSITIONS = [
        Positions::SacEntryFee,
        Positions::SectionEntryFee
      ].freeze

      attr_reader :member

      def initialize(member)
        @member = member
      end

      def generate(role)
        case role
        when Member::MAIN_MEMBERSHIP_ROLE then membership_positions
        when Member::NEW_ENTRY_ROLE then new_entry_positions(role)
        when Member::NEW_ADDITIONAL_SECTION_ROLE then new_additional_section_positions(role)
        else raise ArgumentError, "Invalid role type #{role.class} given"
        end
      end

      private

      def membership_positions
        positions = build_positions(SAC_POSITIONS + SECTION_POSITIONS,
                                    member.main_membership_role)
        member.additional_membership_roles.each do |role|
          positions.push(*build_positions(SECTION_POSITIONS, role))
        end
        positions
      end

      def new_entry_positions(role)
        build_positions(SAC_POSITIONS + SECTION_POSITIONS + NEW_ENTRY_POSITIONS, role)
      end

      def new_additional_section_positions(role)
        build_positions(SECTION_POSITIONS, role)
      end

      def build_positions(classes, role)
        classes.map { |klass| klass.new(member, role) }.filter(&:active?)
      end

    end
  end
end
