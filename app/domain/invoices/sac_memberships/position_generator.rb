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
        Positions::SacMagazinePostageAbroad,
        Positions::ServiceFee
      ].freeze

      SECTION_POSITIONS = [
        Positions::SectionFee,
        Positions::SectionBulletinPostageAbroad
      ].freeze

      NEW_ENTRY_POSITIONS = [
        Positions::SacEntryFee,
        Positions::SectionEntryFee
      ].freeze

      attr_reader :person

      def initialize(person)
        @person = person
      end

      def membership_positions
        positions = build_positions(SECTION_POSITIONS + SAC_POSITIONS,
                                    person.main_membership_role)
        positions.push(*build_balancing_positions(positions))
        person.additional_membership_roles.each do |role|
          positions.push(*build_positions(SECTION_POSITIONS, role))
        end
        positions
      end

      def new_entry_positions
        role = person.new_entry_membership_role
        return [] unless role

        build_positions(SECTION_POSITIONS + SAC_POSITIONS + NEW_ENTRY_POSITIONS, role)
      end

      def new_additional_section_positions(section)
        role = person.new_additional_section_membership_role(section)
        return [] unless role

        build_positions(SECTION_POSITIONS + [Positions::ServiceFee], role)
      end

      private

      def build_positions(classes, role)
        classes.map { |klass| klass.new(person, role) }.filter(&:active?)
      end

      # Charge section for sac positions that are exempted from
      # the invoice for Ehrenmitglieder or Begünstigte.
      def build_balancing_positions(positions)
        positions.filter_map do |position|
          next unless position.requires_balancing_payment?

          amount = position.amount
          position.amount = 0
          Positions::BalancingPayment.new(person, person.main_membership_role, amount)
        end
      end

    end
  end
end
