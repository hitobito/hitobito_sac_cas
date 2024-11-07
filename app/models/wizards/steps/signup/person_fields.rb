# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Wizards::Steps::Signup::PersonFields < Wizards::Step
  include Wizards::Steps::Signup::PersonCommon

  attribute :gender, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :birthday, :date
  attribute :email, :string
  attribute :address_care_of, :string
  attribute :street, :string
  attribute :housenumber, :string

  attribute :postbox, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string
  attribute :phone_number, :string

  def initialize(...)
    super

    if current_user
      self.id = current_user.id
      self.gender ||= current_user.gender
      self.first_name ||= current_user.first_name
      self.last_name ||= current_user.last_name
      self.birthday ||= current_user.birthday
      self.email ||= current_user.email
      self.address_care_of ||= current_user.address_care_of
      self.street ||= current_user.street
      self.housenumber ||= current_user.housenumber
      self.postbox ||= current_user.postbox
      self.zip_code ||= current_user.zip_code
      self.town ||= current_user.town
      self.country ||= current_user.country
      self.phone_number ||= current_user.phone_numbers.find_by(label: Wizards::Steps::Signup::PersonCommon::PHONE_NUMBER_LABEL)&.number
    else
      self.country ||= Settings.addresses.imported_countries.to_a.first
    end
  end
end
