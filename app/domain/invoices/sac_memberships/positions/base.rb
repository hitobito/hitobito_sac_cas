# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class Base
        class_attribute :group, :section_payment_possible

        attr_reader :member, :membership, :custom_discount, :context
        attr_writer :amount

        delegate :date, :config, :mid_year_discount_factor, :sac, to: :context
        delegate :beitragskategorie, to: :membership

        def initialize(member, membership, custom_discount: nil)
          @member = member
          @membership = membership
          @custom_discount = custom_discount # between 0 and 100
          @context = member.context
        end

        def active?
          true
        end

        def creditor
          sac
        end

        def amount
          return 0 if member.sac_honorary_member?

          @amount ||= [gross_amount, 0].max * discount_factor
        end

        def gross_amount
          beitragskategorie_fee
        end

        def name
          self.class.name.demodulize.underscore
        end

        def article_number
          context.config.send(:"#{name}_article_number")
        end

        def section_pays?
          return @section_pays if defined?(@section_pays)

          @section_pays = section_payment_possible &&
            sac_fee_exemption? &&
            amount.positive?
        end

        def invoice_amount
          section_pays? ? 0 : amount
        end

        def label
          I18n.t("invoices.sac_memberships.positions.#{name}", section: section.to_s)
        end

        def label_group
          group ? I18n.t("invoices.sac_memberships.positions.#{group}") : label
        end

        def label_beitragskategorie
          I18n.t("invoices.sac_memberships.beitragskategorie.#{beitragskategorie}")
        end

        def to_abacus_invoice_position
          Invoices::Abacus::InvoicePosition.new(
            name: label,
            grouping: label_group,
            details: label_beitragskategorie,
            amount: invoice_amount,
            article_number: article_number,
            other_creditor_id: (creditor == section) ? section.id : nil,
            other_debitor_id: section_pays? ? section.id : nil,
            other_debitor_amount: section_pays? ? amount : nil
          )
        end

        def to_h
          {
            name: name,
            group: group,
            amount: amount,
            article_number: article_number,
            creditor: creditor.to_s
          }
        end

        private

        def section
          @section ||= context.fetch_section(membership.section)
        end

        def fee_attr_prefix
          name
        end

        def beitragskategorie_fee(conf = config)
          return 0.0 unless paying_person?

          conf.send(:"#{fee_attr_prefix}_#{beitragskategorie}")
        end

        def paying_person?
          member.paying_person?(beitragskategorie)
        end

        def abroad_postage?
          member.living_abroad? && paying_person?
        end

        def section_fee_exemption?
          section.section_fee_exemption?(member)
        end

        def sac_fee_exemption?
          section.sac_fee_exemption?(member)
        end

        def discount_factor
          if custom_discount
            (100 - custom_discount) / 100.0
          else
            mid_year_discount_factor
          end
        end
      end
    end
  end
end
