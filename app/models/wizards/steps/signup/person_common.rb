# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module Wizards::Steps::Signup::PersonCommon
  extend ActiveSupport::Concern

  PHONE_NUMBER_LABEL = "Mobil"

  included do
    class_attribute :minimum_age, default: SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.begin
    validate :assert_valid_phone_number
    validate :assert_minimum_age
    validates :birthday, presence: true

    attr_reader :person # for :assert_old_enough validation
  end

  module ClassMethods
    def human_attribute_name(attr, options = {})
      super(attr, default: Person.human_attribute_name(attr, options))
    end
  end

  def person_attributes
    attributes.compact.symbolize_keys.except(:phone_number).then do |attrs|
      next attrs if phone_number.blank?

      attrs.merge(phone_numbers_attributes: [{label: PHONE_NUMBER_LABEL, number: phone_number}])
    end
  end

  private

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