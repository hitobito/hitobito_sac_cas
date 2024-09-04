# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class SektionOperation
    include ActiveModel::Model

    def initialize(group:, person_attrs:, register_on:, newsletter:)
      @group = group
      @person_attrs = person_attrs
      @register_on = register_on
      @newsletter = newsletter
    end

    def valid?
      [person, role].all? { |model| validate(model) }
    end

    def save!
      save_person_and_role
      generate_invoice if no_approval_needed? && can_receive_invoice?
      exclude_from_mailing_list if mailing_list && !newsletter
    end

    private

    attr_reader :group, :person_attrs, :register_on, :newsletter

    def validate(model)
      model.valid?.tap do
        model.errors.full_messages.each do |message|
          errors.add(:base, message)
        end
      end
    end

    def save_person_and_role
      person.save! && role.save!
    end

    def person
      @person ||= Person.new(person_attrs)
    end

    def role
      @role ||= (register_on.future? ? build_future_role : build_role)
    end

    def build_future_role
      FutureRole.new(
        person: person,
        group: group,
        convert_on: register_on,
        convert_to: role_type
      ).tap { |r| r.mark_as_coming_from_future_role = true }
    end

    def build_role
      Role.new(
        person: person,
        group: group,
        type: role_type,
        created_at: Time.zone.now,
        delete_on: (Time.zone.today.end_of_year unless neuanmeldung?)
      )
    end

    def generate_invoice
      invoice = ExternalInvoice::SacMembership.create!(
        person: person,
        state: :draft,
        year: invoice_date.year,
        issued_at: invoice_date,
        sent_at: invoice_date,
        link: role.layer_group
      )
      Invoices::Abacus::CreateInvoiceJob.new(invoice, invoice_date, new_entry: true).enqueue!
    end

    def neuanmeldung?
      group.is_a?(Group::SektionsNeuanmeldungenSektion) ||
        group.is_a?(Group::SektionsNeuanmeldungenNv)
    end

    def invoice_date
      @invoice_date ||= begin
        invoice_cutoff_date = (register_on - 1.month).change(day: 15)
        [Date.current, invoice_cutoff_date].max
      end
    end

    def role_type = group.self_registration_role_type

    def mailing_list = @mailing_list ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)

    def exclude_from_mailing_list = mailing_list.subscriptions.create!(subscriber: person, excluded: true)

    def no_approval_needed? = Group::SektionsNeuanmeldungenSektion.where(layer_group_id: role.group.layer_group_id).none?

    def can_receive_invoice? = !role.beitragskategorie&.family? || role.person.sac_family_main_person
  end
end
