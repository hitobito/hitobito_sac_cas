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

      Group::SektionsTourenkommission::Tourenleiter,
      Group::SektionsTourenkommission::TourenleiterOhneQualifikation,

      Group::SektionsExterneKontakte::Kontakt,
      Group::ExterneKontakte::Kontakt
    ].freeze

    attribute :terminate_on, :date
    attribute :subscribe_newsletter, :boolean
    attribute :subscribe_fundraising_list, :boolean
    attribute :data_retention_consent, :boolean
    attribute :termination_reason_id, :integer

    validates :terminate_on, inclusion: { in: ->(_) { acceptable_termination_dates } }
    validates :termination_reason_id, presence: true

    delegate :person, to: '@role'

    def self.acceptable_termination_dates
      [Time.zone.yesterday, Time.zone.now.end_of_year.to_date]
    end

    def initialize(role, terminate_on, **params)
      @role = role
      super(params.merge(terminate_on: terminate_on))

      assert_sektions_mitglied
      assert_main_person_if_family
      assert_not_already_terminated
      assert_not_already_deleted
    end

    def save
      valid? && save_roles.all? && save_people.all?
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
      person.roles.select { |role| types.include?(role.type) || types.include?(role.convert_to) }
    end

    def apply_role_changes(role)
      role.write_attribute(:terminated, true)
      role.termination_reason_id = termination_reason_id

      if terminate_on.future?
        role.delete_on ||= [terminate_on, role.delete_on].compact.min
      else
        role.delete_on = nil
        role.deleted_at = terminate_on
      end
    end

    def build_future_role(person)
      return unless data_retention_consent && basic_login_group

      person.roles.build(
        group: basic_login_group,
        type: FutureRole.sti_name,
        convert_to: Group::AboBasicLogin::BasicLogin.sti_name,
        convert_on: terminate_on + 1.day
      )
    end

    def save_people
      affected_people.each do |person|
        person.subscriptions.destroy_all
        subscribe_to(newsletter, person) if subscribe_newsletter
        subscribe_to(fundraising, person) if subscribe_fundraising_list
        person.update(data_retention_consent: data_retention_consent)
      end
    end

    def subscribe_to(mailing_list, person)
      mailing_list&.subscriptions&.create!(subscriber: person)
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
      raise 'not a member' unless @role.is_a?(Group::SektionsMitglieder::Mitglied)
    end

    def assert_not_already_terminated
      raise 'already terminated' if @role.terminated?
    end

    def assert_not_already_deleted
      raise 'already deleted' if @role.deleted_at?
    end

    def assert_main_person_if_family
      if @role.beitragskategorie&.family? && !@role.person.sac_family_main_person
        raise 'not family main person'
      end
    end
  end
end
