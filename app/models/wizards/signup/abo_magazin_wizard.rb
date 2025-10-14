# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboMagazinWizard < AboBasicLoginWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboMagazin::PersonFields,
      Wizards::Steps::Signup::AboMagazin::Summary
    ]

    self.asides = ["aside_abo"]

    RESTRICTED_ROLES = [
      Group::AboMagazin::Abonnent.sti_name,
      Group::AboMagazin::Neuanmeldung.sti_name,
      Group::AboMagazin::Gratisabonnent.sti_name
    ].freeze

    delegate :newsletter, to: :summary

    def member_or_applied? # rubocop:todo Metrics/CyclomaticComplexity
      current_user&.roles&.where(group: group)&.map(&:type)&.any? { |type|
        RESTRICTED_ROLES.include?(type)
      }
    end

    def save!
      super.then do
        role.update!(start_on: Time.zone.today, end_on: 31.days.from_now)
        generate_invoice if Settings.invoicing&.abo_magazin&.automatic_invoice_enabled
      end
    end

    def redirection_message = I18n.t("groups.self_registration.create.already_subscribed_to_abo")

    def requires_policy_acceptance? = false

    def calculated_costs
      if person.living_abroad?
        annual_fee + abroad_fee
      else
        annual_fee
      end
    end

    def shipping_country
      if person.living_abroad?
        I18n.t("groups.self_registration.abo_infos.international")
      else
        I18n.t("groups.self_registration.abo_infos.switzerland")
      end
    end

    def shipping_abroad? = true

    def enqueue_notification_email
      Signup::AboMagazinMailer
        .confirmation(person, group, newsletter)
        .deliver_later
    end

    private

    def generate_invoice
      invoice = ExternalInvoice::AboMagazin.create!(
        person: person,
        state: :draft,
        year: Date.current.year,
        issued_at: Date.current,
        sent_at: Date.current,
        link: group
      )
      Invoices::Abacus::CreateAboMagazinInvoiceJob.new(invoice, role.id).enqueue!
    end

    def build_role(person)
      # The TransmitPersonJob is enqueued with the creation of the new role.
      # Because the CreateAboMagazinInvoiceJob also transmits the person, this
      # would lead to race conditions. Hence skip the TransmitPersonJob.
      super.tap do |role|
        role.skip_transmit_to_abacus = true
      end
    end

    def annual_fee = Group.root.abo_alpen_fee || 0

    def abroad_fee = Group.root.abo_alpen_postage_abroad || 0
  end
end
