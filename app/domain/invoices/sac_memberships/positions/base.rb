# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class Base

        class_attribute :group, :balancing_payment_possible

        attr_reader :person, :role, :context
        attr_writer :amount

        delegate :date, :config, :mid_year_discount, :sac, to: :context
        delegate :beitragskategorie, to: :role

        def initialize(person, role)
          @person = person
          @role = role
          @context = person.context
        end

        def active?
          true
        end

        def debitor
          person
        end

        def creditor
          sac
        end

        def amount
          return 0 if person.sac_honorary_member?

          @amount ||= [gross_amount, 0].max * mid_year_discount
        end

        def gross_amount
          beitragskategorie_fee
        end

        def name
          self.class.name.demodulize.underscore
        end

        def article_number
          context.config.send("#{name}_article_number")
        end

        def requires_balancing_payment?
          balancing_payment_possible &&
            sac_fee_exemption? &&
            amount.positive?
        end

        def to_h
          {
            name: name,
            group: group,
            amount: amount,
            article_number: article_number,
            debitor: debitor.to_s,
            creditor: creditor.to_s
          }
        end

        private

        def section
          @section ||= context.fetch_section(role)
        end

        def fee_attr_prefix
          name
        end

        def beitragskategorie_fee(conf = config)
          return 0.0 unless paying_person?

          conf.send("#{fee_attr_prefix}_#{beitragskategorie}")
        end

        def paying_person?
          !beitragskategorie.family? || person.sac_family_main_person?
        end

        def abroad_postage?
          person.living_abroad? && paying_person?
        end

        def section_fee_exemption?
          section.section_fee_exemption?(person)
        end

        def sac_fee_exemption?
          section.sac_fee_exemption?(person)
        end

      end
    end
  end
end
