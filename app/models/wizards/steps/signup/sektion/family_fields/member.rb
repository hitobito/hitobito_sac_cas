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
    attribute :email, :string
    attribute :birthday, :date
    attribute :phone_number, :string
    attribute :_destroy, :boolean

    validates :first_name, :last_name, presence: true
    validate :assert_family_age, if: :birthday
    validate :assert_email_unique, if: :email

    delegate :emails, to: "@family_fields"

    def initialize(family_fields, attrs = {})
      @family_fields = family_fields
      super(attrs.compact_blank)
    end

    def adult?
      Person.new(birthday: birthday).adult?
    end

    private

    def assert_email_unique
      if emails.include?(email) || Person.exists?(email: email)
        errors.add(:email, :taken)
      end
      emails.push(email)
    end

    def assert_family_age
      calculator = SacCas::Beitragskategorie::Calculator.new(Person.new(birthday: birthday))
      return if calculator.family_age? # everyting in order, no need to check further
      errors.add(:birthday, :youth_not_allowed_in_family) if calculator.youth?
    end
  end
end
