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
      Wizards::Steps::Signup::Sektion::VariousFields,
      Wizards::Steps::Signup::Sektion::CornercardFields,
      Wizards::Steps::Signup::Sektion::SummaryFields
    ]

    self.asides = ["aside_sektion"]

    MIN_ADULT_YEARS = SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.begin
    MIN_CORNERCARD_YEARS = 18
    ADDRESS_KEYS = %i[address_care_of street housenumber postbox zip_code town country]

    delegate :person_attributes, :birthday, to: :person_fields
    delegate :self_registration_reason_id, to: :various_fields
    delegate :newsletter, :privacy_policy_accepted_at, to: :summary_fields

    delegate :unknown?, :adult?, :youth?, :family?, to: :beitragskategorie, prefix: true

    public :group

    def member_or_applied?
      current_user&.sac_membership&.stammsektion_role ||
        current_user&.sac_membership&.neuanmeldung_stammsektion_role
    end

    def redirection_message
      I18n.t("groups.self_registration.create.existing_membership_notice")
    end

    def save!
      valid? && operations.all?(&:save!) && create_people_managers && create_cornercard_upload
    end

    def birthdays
      read_birthdays
    end

    def fee
      fees_for(beitragskategorie)
    end

    def fees_for(beitragskategorie)
      Invoices::SacMemberships::SectionSignupFeePresenter.new(
        group.layer_group,
        beitragskategorie,
        person
      )
    end

    private

    # As we might save multiple people we delegate validation to operations
    # person itself can be invalid as operation handles aspects
    # e.g role start_on and gender I18nEnum::NIL_KEY
    def person_valid? = operations_valid?

    def beitragskategorie
      value = if birthdays.none?
        :unknown
      elsif birthdays.many?
        :family
      else
        Person.new(birthday: birthdays.first).youth? ? :youth : :adult
      end
      ActiveSupport::StringInquirer.new(value.to_s)
    end

    def operations
      @operations ||= people_attrs.map do |person_attrs|
        SektionOperation.new(person_attrs:, group:, newsletter:)
      end
    end

    def operations_valid?
      return true unless last_step?

      operations.all? do |operation|
        next true if operation.valid?

        operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end

        false
      end
    end

    def create_people_managers
      return true unless household_key

      main_person = operations.find { |o| o.person.sac_family_main_person }.person
      main_person.household.create_missing_people_managers(main_person)
      true
    end

    def create_cornercard_upload
      return true unless step(:cornercard_fields)&.card_application

      main_person = operations.first.person
      main_person.create_cornercard_upload!
    end

    def people_attrs
      main_person_attrs = main_person_attributes.merge(common_person_attrs)
      merge_attrs = main_person_attrs.slice(*ADDRESS_KEYS, *common_person_attrs.keys)
      members.map { |member|
        member.person_attributes.merge(merge_attrs)
      }.unshift(main_person_attrs)
    end

    def main_person_attributes
      person_fields.person_attributes.merge(email:).tap do |attrs|
        attrs[:sac_family_main_person] = true if household_key
      end
    end

    def common_person_attrs
      {self_registration_reason_id:, privacy_policy_accepted_at:, household_key:}.compact_blank
    end

    def members = respond_to?(:family_fields) ? family_fields.members : []

    def person_attributes = person_fields.person_attributes.merge(email:)

    def household_key
      @household_key ||= Household.new(Person.new).send(:next_key) if members.any?
    end

    def read_birthdays
      members.map(&:birthday).unshift(birthday).compact_blank.map { |birthday|
        I18n.l(birthday)
      }.shuffle
    end

    def step_after(step_name_or_class) # rubocop:todo Metrics/CyclomaticComplexity
      step = step_name_or_class # shorten name here, but keep documenting quality

      return person_fields_step if step == :_start && current_user
      return various_fields_step if at_person_fields?(step) && too_young_for_household?
      return summary_fields_step if at_various_fields?(step) && too_young_for_cornercard?

      super
    end

    def various_fields_step = Wizards::Steps::Signup::Sektion::VariousFields.step_name

    def summary_fields_step = Wizards::Steps::Signup::Sektion::SummaryFields.step_name

    def person_fields_step = Wizards::Steps::Signup::Sektion::PersonFields.step_name

    def at_person_fields?(step) = step == Wizards::Steps::Signup::Sektion::PersonFields

    def at_various_fields?(step) = step == Wizards::Steps::Signup::Sektion::VariousFields

    def too_young_for_household? = has_needed_age(MIN_ADULT_YEARS)

    def too_young_for_cornercard? = has_needed_age(MIN_CORNERCARD_YEARS)

    def has_needed_age(age)
      birthday =
        params.with_indifferent_access.dig(:person_fields, :birthday) ||
        current_user&.birthday

      return false unless birthday

      ::Person.new(birthday:).years.to_i < age
    end
  end
end
