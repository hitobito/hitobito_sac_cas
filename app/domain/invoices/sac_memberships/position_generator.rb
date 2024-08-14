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

      attr_reader :member, :custom_discount

      def initialize(member, custom_discount: nil)
        @member = member
        @custom_discount = custom_discount
      end

      # new_entry ist nur bei Neueintritt SAC gesetzt, nicht bei Sektionseintritten
      def generate(memberships, new_entry: false)
        main = memberships.find(&:main)

        main_positions(main) +
          additional_positions(memberships) +
          new_entry_positions(main, new_entry)
      end

      private

      def main_positions(main_membership)
        return [] unless main_membership

        build_positions(SAC_POSITIONS, main_membership)
      end

      def additional_positions(memberships)
        memberships.flat_map do |membership|
          build_positions(SECTION_POSITIONS, membership)
        end
      end

      def new_entry_positions(main_membership, new_entry)
        return [] if !new_entry || !main_membership

        build_positions(NEW_ENTRY_POSITIONS, main_membership)
      end

      def build_positions(classes, membership)
        classes
          .map { |klass| klass.new(member, membership, custom_discount: custom_discount) }
          .filter(&:active?)
      end
    end
  end
end
