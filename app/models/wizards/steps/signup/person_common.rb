# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::PersonCommon
  extend ActiveSupport::Concern

  PHONE_NUMBER_LABEL = "Mobil"

  included do
    class_attribute :minimum_age, default: SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.begin
    validate :assert_valid_phone_number
    validate :assert_minimum_age
    validates :gender, :first_name, :last_name, :birthday, presence: true

    attribute :id, :integer # for when dealing with persisted users

    attr_reader :person # for :assert_old_enough validation

    include I18nEnums

    i18n_enum :gender, Person::GENDERS + [I18nEnums::NIL_KEY], i18n_prefix: "activerecord.attributes.person.genders"
  end

  module ClassMethods
    def human_attribute_name(attr, options = {})
      super(attr, default: Person.human_attribute_name(attr, options))
    end
  end

  def person_attributes
    attributes.compact.symbolize_keys.except(:phone_number).then do |attrs|
      next attrs if phone_number.blank?

      attrs.merge(phone_numbers_attributes: [{label: PHONE_NUMBER_LABEL, number: phone_number, id: phone_number_id}.compact])
    end
  end

  private

  def phone_number_id
    PhoneNumber.find_by(label: PHONE_NUMBER_LABEL, contactable_id: id, contactable_type: Person.sti_name)&.id if id
  end

  def assert_valid_phone_number
    if phone_number.present? && PhoneNumber.new(number: phone_number).tap(&:valid?).errors.key?(:number)
      errors.add(:phone_number, :invalid)
    end
  end

  def assert_minimum_age
    if minimum_age && birthday && Person.new(birthday: birthday).years < minimum_age
      errors.add(:person, :too_young, minimum_years: minimum_age)
    end
  end
end
