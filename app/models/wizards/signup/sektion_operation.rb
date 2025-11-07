# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class SektionOperation
    include ActiveModel::Model

    def initialize(group:, person_attrs:, newsletter:)
      @group = group
      person_attrs[:gender] = nil if person_attrs[:gender] == I18nEnums::NIL_KEY
      @person_attrs = person_attrs
      @newsletter = newsletter
    end

    def valid?
      [person, role].all? { |model| validate(model) }
    end

    def save! # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
      raise "cannot save invalid model: \n#{errors.full_messages}" unless valid?

      save_person_and_role

      if paying_person?
        if no_approval_needed?
          generate_invoice
          enqueue_confirmation_mail
        else
          enqueue_approval_pending_confirmation_mail
        end
      end
      mailing_list&.subscribe_if(person, newsletter)

      enqueue_notification_email
      enqueue_duplicate_locator_job if new_record?
      send_password_reset_email if new_record?
      true
    end

    private

    attr_reader :group, :person_attrs, :newsletter

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

    def paying_person?
      role.person.sac_membership.paying_person?(role.beitragskategorie)
    end

    def person
      @person ||= build_or_find_person.tap do |p|
        p.attributes = person_attrs
      end
    end

    def build_or_find_person
      new_record? ? Person.new(language: I18n.locale) : Person.find(person_attrs[:id])
    end

    def role
      @role ||= build_role
    end

    def build_role
      Role.new(
        person: person,
        group: group,
        type: role_type,
        start_on: today,
        end_on: (today unless neuanmeldung?)
      )
    end

    def generate_invoice
      invoice = ExternalInvoice::SacMembership.create!(
        person: person,
        state: :draft,
        year: today.year,
        issued_at: today,
        sent_at: today,
        link: role.layer_group
      )
      Invoices::Abacus::CreateMembershipInvoiceJob
        .new(invoice, today, new_entry: true, dispatch_type: :digital)
        .enqueue!
    end

    def enqueue_confirmation_mail
      Signup::SektionMailer
        .confirmation(person, group.layer_group, role.beitragskategorie)
        .deliver_later
    end

    def enqueue_approval_pending_confirmation_mail
      Signup::SektionMailer
        .approval_pending_confirmation(person, group.layer_group, role.beitragskategorie)
        .deliver_later
    end

    def neuanmeldung?
      group.is_a?(Group::SektionsNeuanmeldungenSektion) ||
        group.is_a?(Group::SektionsNeuanmeldungenNv)
    end

    def today = @today ||= Date.current

    def role_type = group.self_registration_role_type

    def mailing_list
      @mailing_list ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
    end

    def new_record? = person_attrs[:id].blank?

    def no_approval_needed?
      role.group.layer_group.decorate.membership_admission_through_gs?
    end

    def enqueue_duplicate_locator_job
      Person::DuplicateLocatorJob.new(person.id).enqueue!
    end

    def enqueue_notification_email
      return if group.self_registration_notification_email.blank?

      Groups::SelfRegistrationNotificationMailer
        .self_registration_notification(group.self_registration_notification_email, role)
        .deliver_later
    end

    def send_password_reset_email
      Person.send_reset_password_instructions(email: person.email) if person.email.present?
    end
  end
end
