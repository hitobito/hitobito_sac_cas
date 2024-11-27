# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class TerminateSacMembership
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    include CommonApi

    RELEVANT_ROLES = [
      Group::SektionsMitglieder::Mitglied,
      Group::SektionsMitglieder::MitgliedZusatzsektion,
      Group::SektionsMitglieder::Beguenstigt,
      Group::Ehrenmitglieder::Ehrenmitglied,

      Group::SektionsNeuanmeldungenNv::Neuanmeldung,
      Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
      Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion,

      Group::SektionsTourenUndKurse::Tourenleiter,
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation,

      Group::ExterneKontakte::Kontakt
    ].freeze

    attribute :terminate_on, :date
    attribute :subscribe_newsletter, :boolean, default: false
    attribute :subscribe_fundraising_list, :boolean, default: false
    attribute :data_retention_consent, :boolean, default: false
    attribute :termination_reason_id, :integer

    validates :terminate_on, inclusion: {in: ->(_) { acceptable_termination_dates }}
    validates :termination_reason_id, presence: true

    delegate :person, to: "@role"

    def self.acceptable_termination_dates
      [Time.zone.yesterday, Time.zone.now.end_of_year.to_date]
    end

    def initialize(role, terminate_on, backoffice: false, **params)
      @role = role
      @backoffice = backoffice
      super(params.merge(terminate_on: terminate_on))

      assert_sektions_mitglied
      assert_main_person_if_family
      assert_not_already_terminated
      assert_not_already_ended
    end

    def save
      valid?.tap do
        destroy_future_roles
        save_roles
        save_people
      end
    end

    private

    def prepare_roles(person)
      mark_active_roles(person) + Array(build_future_role(person))
    end

    def mark_active_roles(person)
      relevant_roles(person).each do |role|
        apply_role_changes(role)
      end
    end

    def relevant_roles(person)
      types = RELEVANT_ROLES.map(&:to_s)
      person.roles.select { |role| types.include?(role.type) }
    end

    def membership_end_on
      original_membership_end_on = person.sac_membership.stammsektion_role.end_on
      [terminate_on, original_membership_end_on].compact.min
    end

    def apply_role_changes(role)
      role.write_attribute(:terminated, true)
      role.termination_reason_id = termination_reason_id

      role.end_on = membership_end_on
    end

    def build_future_role(person)
      return unless data_retention_consent && basic_login_group

      person.roles.build(
        group: basic_login_group,
        type: Group::AboBasicLogin::BasicLogin.sti_name,
        start_on: membership_end_on + 1.day
      )
    end

    def destroy_future_roles
      Role.future
        .where(person: affected_people, type: RELEVANT_ROLES.map(&:sti_name))
        .destroy_all
    end

    def save_people
      affected_people.each do |person|
        person.subscriptions.destroy_all
        subscribe_to(newsletter, person) if subscribe_newsletter
        subscribe_to(fundraising, person) if subscribe_fundraising_list
        person.update(data_retention_consent: data_retention_consent)
        cancel_open_membership_invoices(person)
      end
    end

    def subscribe_to(mailing_list, person)
      mailing_list&.subscriptions&.find_or_create_by!(subscriber: person)
    end

    def cancel_open_membership_invoices(person)
      person.external_invoices.open.where(type: ExternalInvoice::SacMembership.sti_name).find_each do |invoice|
        invoice.update!(state: "cancelled")
        Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
      end
    end

    def basic_login_group
      @basic_login_group ||= Group::AboBasicLogin.find_by(layer_group_id: Group.root.id)
    end

    def newsletter
      @newsletter ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
    end

    def fundraising
      @fundraising ||= MailingList.find_by(id: Group.root.sac_fundraising_mailing_list_id)
    end

    def assert_sektions_mitglied
      raise "not a member" unless @role.is_a?(Group::SektionsMitglieder::Mitglied)
    end

    def assert_not_already_terminated
      raise "already terminated" if @role.terminated? && !@backoffice
    end

    def assert_not_already_ended
      raise "already deleted" if @role.end_on&.past?
    end

    def assert_main_person_if_family
      if @role.beitragskategorie&.family? && !@role.person.sac_family_main_person
        raise "not family main person"
      end
    end
  end
end
