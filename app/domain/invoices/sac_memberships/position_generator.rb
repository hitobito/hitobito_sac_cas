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

      attr_reader :person

      def initialize(person)
        @person = person
      end

      def generate
        positions = collect_main_membership_positions
        person.additional_membership_roles.each do |role|
          positions.push(*build_positions(SECTION_POSITIONS, role))
        end
        positions.filter(&:active?)
      end

      private

      def collect_main_membership_positions
        role = person.main_membership_role
        positions = []
        positions.push(*build_positions(SECTION_POSITIONS, role))
        positions.push(*build_positions(SAC_POSITIONS, role))
        positions.push(*build_balancing_positions(positions, role))
        positions
      end

      def build_positions(classes, role)
        classes.map { |klass| klass.new(person, role) }
      end

      # Charge section for sac positions that are exempted from
      # the invoice for Ehrenmitglieder or Begünstigte.
      def build_balancing_positions(positions, role)
        positions.filter_map do |position|
          next unless position.requires_balancing_payment?

          amount = position.amount
          position.amount = 0
          Positions::BalancingPayment.new(person, role, amount)
        end
      end

    end
  end
end
