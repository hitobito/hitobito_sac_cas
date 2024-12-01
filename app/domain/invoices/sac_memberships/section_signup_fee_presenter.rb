# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class SectionSignupFeePresenter
      include ActionView::Helpers::NumberHelper

      ABROAD_POSITIONS = [
        Positions::SectionBulletinPostageAbroad,
        Positions::SacMagazinePostageAbroad
      ].freeze

      ANNUAL_POSITIONS =
        PositionGenerator::SAC_POSITIONS +
        PositionGenerator::SECTION_POSITIONS -
        ABROAD_POSITIONS

      NEW_ENTRY_POSITIONS = PositionGenerator::NEW_ENTRY_POSITIONS

      Line = Data.define(:label, :amount) do
        def to_s = "#{label} #{amount}"
      end

      attr_reader :section

      def initialize(section, beitragskategorie, person, main: true, date: Time.zone.today)
        @section = section
        @date = date
        @main = main
        @person = prepare(person)
        @beitragskategorie = ActiveSupport::StringInquirer.new(beitragskategorie.to_s)
      end

      def lines
        @lines ||= [:annual_fee, :discount, :entry_fee, :abroad_fee].collect do |position|
          Line.new(translate_position_text(position), format_position_amount(position)) if send(position).positive?
        end.compact + [Line.new(translate_position_text(:total_amount), format_position_amount(:total_amount))]
      end

      def summary
        @summary ||= Line.new(translate_position_text("beitragskategorien.#{beitragskategorie}"), build_summary_amount)
      end

      def annual_fee = summed_positions(ANNUAL_POSITIONS, :gross_amount)

      def entry_fee = summed_positions(NEW_ENTRY_POSITIONS, :gross_amount)

      def abroad_fee = summed_positions(ABROAD_POSITIONS, :amount) # with already applied discount

      def discount = annual_fee * (1 - discount_factor)

      def total_amount = (annual_fee + entry_fee + abroad_fee - discount)

      def positions = @positions ||= build_positions

      private

      attr_reader :beitragskategorie, :main, :date, :person
      delegate :discount_factor, to: :context

      def context = @context ||= Context.new(date)

      def prepare(person)
        return context.people_with_membership_years.find(person.id) if person.persisted?

        person.tap { |p| p.sac_family_main_person = true }
      end

      def build_positions
        member = Member.new(person, context)
        new_entry = !member.stammsektion
        member.sac_magazine = new_entry

        membership = Membership.new(section, beitragskategorie, main)
        PositionGenerator.new(member).generate([membership], new_entry:)
      end

      def build_summary_amount
        parts = [format_position_amount(:annual_fee)]
        if entry_fee.positive?
          parts += [translate_position_text(:entry_fee)]
          parts += [format_position_amount(:entry_fee)]
        end
        parts.join(" ")
      end

      def format_position_amount(position)
        value = send(position)
        formatted_value = number_with_precision(value,
          precision: I18n.t("number.currency.format.precision"),
          delimiter: I18n.t("number.currency.format.delimiter"))
        [I18n.t("global.currency"), formatted_value].join(" ")
      end

      def translate_position_text(position)
        options = {scope: i18n_scope}
        options[:percent] = ((1 - discount_factor) * 100).to_i if /discount/.match?(position)
        I18n.t(position, **options)
      end

      def i18n_scope = @i18n_scope ||= self.class.to_s.underscore.tr("/", ".")

      def summed_positions(relevant_positions, method) = positions.select { |p| relevant_positions.include?(p.class) }.sum(&method)
    end
  end
end
