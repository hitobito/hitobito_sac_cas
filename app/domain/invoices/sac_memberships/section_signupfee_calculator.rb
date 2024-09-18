# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class SectionSignupfeeCalculator
      COMMON_POSITIONS = [
        Positions::SacFee,
        Positions::SectionFee,
        Positions::HutSolidarityFee,
        Positions::SacMagazine,
      ].freeze

      NEW_ENTRY_POSITIONS = [
        Positions::SacEntryFee,
        Positions::SectionEntryFee
      ].freeze

      delegate :discount_factor, to: :context

      def initialize(section, beitragskategorie, date = Time.zone.today)
        @section = section
        @beitragskategorie = beitragskategorie
        @context = Context.new(date)
      end

      def annual_fee
        build_positions(COMMON_POSITIONS).sum(&:gross_amount) * discount_factor
      end

      def entry_fee
        build_positions(NEW_ENTRY_POSITIONS).sum(&:gross_amount)
      end

      def total_amount
        annual_fee + entry_fee
      end

      private

      attr_reader :member, :section, :beitragskategorie, :context, :sac_magazine

      def build_positions(classes)
        classes.map { |klass| klass.new(member, membership) }
               .filter(&:active?)
      end

      def membership = @membership ||= Membership.new(section, beitragskategorie, nil)

      def person = @person ||= Person.new(sac_family_main_person: true)

      def member = @member ||= Member.new(person, context)
    end
  end
end
