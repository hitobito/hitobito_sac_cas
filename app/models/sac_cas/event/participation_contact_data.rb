# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationContactData
  extend ActiveSupport::Concern

  prepended do
    attr_reader :event

    delegate :salutation_label, to: :person

    delegate :subsidy?, :subsidizable?, to: :participation

    class << self
      delegate :human_attribute_name, to: Wizards::Steps::Signup::PersonFields
    end

    self.contact_attrs = [:first_name, :last_name, :email, :address_care_of, :street, :housenumber,
      :postbox, :zip_code, :town, :country, :gender, :birthday, :phone_numbers]

    self.mandatory_contact_attrs = [:email, :first_name, :last_name, :birthday, :street,
      :housenumber, :zip_code, :town, :country]
  end

  private

  def participation
    @participation ||= Event::Participation.new(event: @event, person: @person)
  end

  def assert_required_contact_attrs_valid
    super.tap do
      person.phone_numbers.first.valid?

      message = [
        Wizards::Steps::Signup::PersonFields.human_attribute_name(:phone_number), t("errors.messages.blank")
      ].join(" ")
      errors.add(:base, message) if person.phone_numbers.first.number.blank?
    end
  end
end
