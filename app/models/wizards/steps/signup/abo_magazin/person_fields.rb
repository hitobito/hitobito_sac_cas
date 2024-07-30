# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::AboMagazin
  class PersonFields < Wizards::Steps::NewUserForm
    include Wizards::Steps::Signup::PersonCommon
    include Wizards::Steps::Signup::AgreementFields

    self.partial = "wizards/steps/signup/abo_basic_login/person_fields"
    self.minimum_age = 18

    attribute :gender, :string
    attribute :birthday, :date
    attribute :address_care_of, :string
    attribute :street, :string
    attribute :housenumber, :string

    attribute :postbox, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :phone_number, :string

    validates :street, :housenumber, :town, :zip_code,
      :country, :phone_number, presence: true

    NON_ASSIGNABLE_ATTRS = Wizards::Steps::Signup::AgreementFields::AGREEMENTS + [:newsletter]

    def initialize(...)
      super
      self.country ||= Settings.addresses.imported_countries.to_a.first
    end

    def person_attributes
      super.except(*NON_ASSIGNABLE_ATTRS)
    end
  end
end
