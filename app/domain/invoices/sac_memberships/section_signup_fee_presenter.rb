# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class SectionSignupFeePresenter
      include ActionView::Helpers::NumberHelper

      COMMON_POSITIONS = [
        Positions::SacFee,
        Positions::SectionFee,
        Positions::HutSolidarityFee,
        Positions::SacMagazine
      ].freeze

      ABROAD_POSITIONS = [
        Positions::SectionBulletinPostageAbroad,
        Positions::SacMagazinePostageAbroad
      ].freeze

      NEW_ENTRY_POSITIONS = [
        Positions::SacEntryFee,
        Positions::SectionEntryFee
      ].freeze

      Line = Data.define(:amount, :label)

      delegate :discount_factor, to: :context
      attr_reader :beitragskategorie, :section, :skip_entry_fee

      def initialize(section, beitragskategorie, date: Time.zone.today, country: nil, sac_magazine: false, skip_entry_fee: false)
        @section = section
        @beitragskategorie = ActiveSupport::StringInquirer.new(beitragskategorie.to_s)
        @context = Context.new(date)
        @i18n_scope = self.class.to_s.underscore.tr("/", ".")
        @skip_entry_fee = skip_entry_fee
        person.update(country: country) unless country.nil? # set country during signup process
        member.instance_variable_set(:@sac_magazine, sac_magazine)
        # during the signup process, the member isn't part of the magazine mailing list yet, but
        # will be per default after signup, positions depending on the sac_magazine
        # should be displayed in aside suring signup
      end

      def lines
        @lines ||= [*positions.keys, :total_amount].collect do |position|
          next if position =~ /discount/ && discount_factor == 1 || send(position) == 0
          Line.new(format_position_amount(position), translate_position_text(position))
        end.compact
      end      

      def positions
        base_positions = {
          annual_fee: :+,
          discount: :-,
          entry_fee: :+,
          abroad_fee: :+
        }

        base_positions.delete(:entry_fee) if skip_entry_fee
        base_positions
      end      

      def beitragskategorie_label
        I18n.t("beitragskategorien.#{beitragskategorie}", scope: i18n_scope)
      end

      def beitragskategorie_amount
        parts = [format_position_amount(:annual_fee)]
        if entry_fee.positive? && !skip_entry_fee
          parts += [translate_position_text(:entry_fee)]
          parts += [format_position_amount(:entry_fee)]
        end
        parts.join(" ")
      end

      def annual_fee
        build_positions(COMMON_POSITIONS).sum(&:gross_amount)
      end

      def entry_fee
        build_positions(NEW_ENTRY_POSITIONS).sum(&:gross_amount)
      end

      def abroad_fee
        build_positions(ABROAD_POSITIONS).sum(&:gross_amount)
      end

      def discount
        annual_fee * (1 - discount_factor)
      end

      def total_amount
        positions.reduce(0) do |total, (position, operation)|
          total.send(operation, send(position))
        end
      end      

      private

      attr_reader :context, :sac_magazine, :i18n_scope

      def build_positions(classes)
        classes.map { |klass| klass.new(member, membership) }
          .filter(&:active?)
      end

      def membership = @membership ||= Membership.new(section, beitragskategorie, nil)

      def person = @person ||= Person.new(sac_family_main_person: true)

      def member = @member ||= Member.new(person, context)

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
    end
  end
end
