# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class SektionWizard < Wizards::RegisterNewUserWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::Sektion::PersonFields,
      Wizards::Steps::Signup::Sektion::FamilyFields,
      Wizards::Steps::Signup::Sektion::VariousFields
    ]

    MIN_ADULT_YEARS = SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.begin

    delegate :email, to: :main_email_field
    delegate :person_attributes, :birthday, to: :person_fields
    delegate :newsletter, :self_registration_reason_id, :privacy_policy_accepted_at, to: :various_fields

    public :group

    def save!
      valid? && operations.all?(&:save!)
    end

    def valid?
      super && operations_valid?
    end

    def birthdays
      read_birthdays
    end

    private

    def operations
      @operation ||= people_attrs.map do |person_attrs|
        SektionOperation.new(person_attrs:, group:, register_on:, newsletter:)
      end
    end

    def operations_valid?
      return true unless last_step?

      operations.all? do |operation|
        next true if operation.valid?
        operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      end
    end

    def people_attrs
      members
        .map(&:person_attributes)
        .unshift(main_person_attributes)
        .map { |attrs| attrs.merge(common_person_attrs) }
    end

    def main_person_attributes
      person_fields.person_attributes.merge(email:).tap do |attrs|
        attrs[:sac_family_main_person] = true if household_key
      end
    end

    def common_person_attrs
      {
        self_registration_reason_id:,
        privacy_policy_accepted_at:,
        household_key: household_key
      }.compact_blank
    end

    def register_on = various_fields.register_on_date || Time.zone.today

    def members = respond_to?(:family_fields) ? family_fields.members : []

    def person_attributes = person_fields.person_attributes.merge(main_email_field.attributes)

    def household_key
      @household_key ||= ::Person::Household.next_key if members.any?
    end

    def read_birthdays
      members.map(&:birthday).unshift(birthday).compact_blank.map { |birthday| I18n.l(birthday) }.shuffle
    end

    def step_after(step_name_or_class)
      if step_name_or_class == Wizards::Steps::Signup::Sektion::PersonFields && too_young_for_household?
        Wizards::Steps::Signup::Sektion::VariousFields.step_name
      else
        super
      end
    end

    def too_young_for_household?
      birthday = params.with_indifferent_access.dig(:person_fields, :birthday)

      if birthday
        years = ::Person.new(birthday: birthday).years
        years && years <= MIN_ADULT_YEARS
      end
    end
  end
end