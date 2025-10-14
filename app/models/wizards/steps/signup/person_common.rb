# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::PersonCommon
  extend ActiveSupport::Concern

  PHONE_NUMBER_LABEL = "mobile"

  included do
    class_attribute :minimum_age,
      default: SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.begin
    class_attribute :maximum_age,
      default: SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.end

    validate :assert_valid_phone_number
    validate :assert_minimum_age
    validate :assert_maximum_age

    attribute :id, :integer # for when dealing with persisted users

    attr_reader :person # for :assert_old_enough validation

    include I18nEnums

    i18n_enum :gender, Person::GENDERS + [I18nEnums::NIL_KEY],
      i18n_prefix: "activerecord.attributes.person.genders"
  end

  module ClassMethods
    def human_attribute_name(attr, options = {})
      super(attr, default: Person.human_attribute_name(attr, options))
    end
  end

  def person_attributes
    attributes.compact.symbolize_keys.except(:phone_number).then do |attrs|
      attrs[:gender] = nil if attrs[:gender] == I18nEnums::NIL_KEY
      next attrs if phone_number.blank?

      attrs.merge(phone_number_mobile_attributes: {number: phone_number, id: phone_number_id})
    end
  end

  private

  def phone_number_id
    if id
      PhoneNumber.find_by(label: PHONE_NUMBER_LABEL, contactable_id: id,
        contactable_type: Person.sti_name)&.id
    end
  end

  def assert_valid_phone_number
    # rubocop:todo Layout/LineLength
    if phone_number.present? && PhoneNumber.new(number: phone_number).tap(&:valid?).errors.key?(:number)
      # rubocop:enable Layout/LineLength
      errors.add(:phone_number, :invalid)
    end
  end

  def assert_minimum_age
    if minimum_age && birthday && Person.new(birthday: birthday).years < minimum_age
      errors.add(:person, :too_young, minimum_years: minimum_age)
    end
  end

  def assert_maximum_age
    if maximum_age && birthday && Person.new(birthday: birthday).years > maximum_age
      errors.add(:person, :too_old, maximum_years: maximum_age)
    end
  end
end
