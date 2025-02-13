# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationContactData
  extend ActiveSupport::Concern
  include AssignsSacPhoneNumbers

  prepended do
    attr_reader :event

    delegate :salutation_label, to: :person
    delegate :phone_number_mobile, :build_phone_number_mobile,
      :phone_number_landline, :build_phone_number_landline,
      to: :person

    delegate :subsidy?, :subsidizable?, to: :participation

    class << self
      delegate :human_attribute_name, to: Wizards::Steps::Signup::PersonFields
    end

    self.contact_attrs = [:first_name, :last_name, :email, :address_care_of, :street,
      :housenumber, :postbox, :zip_code, :town, :country, :gender, :birthday,
      :phone_number_mobile, :phone_number_landline]

    self.mandatory_contact_attrs = [:email, :first_name, :last_name, :birthday, :street,
      :housenumber, :zip_code, :town, :country]
  end

  def initialize(event, person, model_params = {})
    super
    mark_phone_numbers_for_destroy(person)
  end

  private

  def participation
    @participation ||= Event::Participation.new(event: @event, person: @person)
  end

  def assert_required_contact_attrs_valid
    super

    # Ensure that at least one phone number is present
    return if PhoneNumber.predefined_labels
      .map { |label| person.send(:"phone_number_#{label}") }
      .select { |phone_number| !phone_number&.marked_for_destruction? }
      .any?

    message = [PhoneNumber.model_name.human, t("errors.messages.blank")].join(" ")
    errors.add(:base, message)
  end
end
