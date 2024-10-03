# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class FamilyFields::Member
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    include Wizards::Steps::Signup::PersonCommon

    attribute :gender, :string
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :birthday, :date

    attribute :email, :string
    attribute :phone_number, :string

    attribute :_destroy, :boolean

    validates :first_name, :last_name, presence: true
    validates :email, presence: true, if: :adult?
    validates :phone_number, presence: true, if: :adult?
    validate :assert_family_age, if: :birthday
    validate :assert_email_unique, if: :email

    def adult?
      Person.new(birthday:).adult?
    end

    def required_attrs
      [:email_required, :phone_number_required]
    end

    private

    def assert_email_unique
      errors.add(:email, :taken) if Person.exists?(email:)
    end

    def assert_family_age
      calculator = SacCas::Beitragskategorie::Calculator.new(Person.new(birthday:))
      return if calculator.family_age? || !calculator.youth? # everything in order, no need to check further

      errors.add(:birthday, :youth_not_allowed_in_family,
        from_age: SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.end.next,
        to_age: SacCas::Beitragskategorie::Calculator::AGE_RANGE_YOUTH.end.pred)
    end
  end
end
