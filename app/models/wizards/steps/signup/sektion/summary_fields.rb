# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class SummaryFields < Wizards::Step
    include Wizards::Steps::Signup::AgreementFields

    DYNAMIC_AGREEMENTS = [
      :sektion_statuten,
      :adult_consent
    ].freeze

    DYNAMIC_AGREEMENTS.each do |agreement|
      attribute agreement, :boolean
      validates agreement, acceptance: true, if: :"requires_#{agreement}?"
    end

    attribute :contribution_regulations, :boolean, default: false

    validates :contribution_regulations, acceptance: true
    validates :register_on, presence: true

    delegate :requires_adult_consent?, to: :wizard

    def sektion_statuten_link_args
      label = I18n.t("link_sektion_statuten_title", scope: "self_registration.infos_component")
      path = rails_blob_path(privacy_policy, disposition: :attachment, only_path: true)
      [label, path]
    end

    def requires_sektion_statuten?
      sektion_statuten.blank? && privacy_policy.attached?
    end

    def privacy_policy_accepted_at
      Time.zone.now if sektion_statuten
    end

    def info_alert_text
      wizard.group.is_a?(Group::SektionsNeuanmeldungenNv) ?
            I18n.t("wizards.steps.signup.sektion.summary_fields.info_alert_neuanmeldungen_nv", name: wizard.group.layer_group.name) :
            I18n.t("wizards.steps.signup.sektion.summary_fields.info_alert_neuanmeldungen_sektion")
    end

    def fee_component
      @fee_component ||= SelfRegistration::FeeComponent.new(group: wizard.group, birthdays: wizard.birthdays)
    end

    def person_info(person)
      {
        title: "Kontaktperson",
        attributes: [
          {value: "#{person.first_name} #{person.last_name}", class: "fw-bold mb-3"},
          {label: translated_label_name(:address_care_of), value: person.address_care_of},
          {label: translated_label_name(:address), value: "#{person.street} #{person.housenumber}"},
          {label: translated_label_name(:postbox), value: person.postbox},
          {label: translated_label_name(:zip_town), value: "#{person.zip_code} #{person.town}"},
          {label: translated_label_name(:county), value: person.country, class: "mb-3"},
          {label: translated_label_name(:birthday), value: person.birthday.strftime("%d.%m.%Y")},
          {label: translated_label_name(:phone_number), value: person.phone_number},
          {label: translated_label_name(:email), value: wizard.email}
        ]
      }
    end

    def family_info
      wizard.family_fields.members.sort_by(&:birthday).map do |member|
        {
          title: member.adult? ? "Erwachsene Person" : "Kind",
          attributes: [
            {value: "#{member.first_name} #{member.last_name}", class: "fw-bold mb-3"},
            {label: translated_label_name(:birthday), value: member.birthday.strftime("%d.%m.%Y")},
            {label: translated_label_name(:phone_number), value: member.phone_number},
            {label: translated_label_name(:email), value: member.email}
          ]
        }
      end
    end

    def entry_fee_info
      {title: "TODO: Einzelmitgliedschaft",
       attributes:
        [
          {value: "Eintritt per: " + I18n.t("activemodel.attributes.self_inscription.register_on_options.#{wizard.various_fields.register_on}"), class: "mb-3"},
          {value: "Sektion #{wizard.group.layer_group.name}", class: "h6 fw-bold"},
          {value: fee_component.annual_fee},
          {value: fee_component.inscription_fee},
          {value: fee_component.total, class: "fw-bold"}
        ]}
    end

    def translated_label_name(attribute)
      # get zip_town translation from contactable fields
      return "#{I18n.t("contactable.fields.#{attribute}")}:" if I18n.exists?("contactable.fields.#{attribute}")

      "#{wizard.person_fields.class.human_attribute_name(attribute)}:"
    end

    private

    def privacy_policy
      @privacy_policy ||= wizard.group.layer_group.privacy_policy
    end
  end
end
