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
  end

  def initialize(event, person, model_params = {})
    super
    mark_phone_numbers_for_destroy(person)
  end

  def mark_as_required?(attr)
    # We specify this specifically, since we want the phone number label to show the required mark
    # Adding the phone_numbers attribute to mandatory_contact_attrs doesnt work, because that also
    # affects the backend validation, participation_contact_data doesnt have a phone_numbers attribute, just
    # multiple different phone_number types
    attr == :phone_numbers
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

    # We add the error message to the contact data object, this is used to display the error message on form submits
    errors.add(:base, t("activerecord.errors.messages.at_least_one_present", model_name: PhoneNumber.model_name.human))

    # We add an active record error on the phone number objects, to mark the form fields as invalid
    PhoneNumber.predefined_labels.map { |label| person.send(:"phone_number_#{label}") }.each do |object|
      next if object.nil?

      object.errors.add(:number)
    end
  end
end
