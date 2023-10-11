# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class Groups::SelfRegistration::MainPerson < Groups::SelfRegistration::Housemate
  self.attrs = [
    :first_name, :last_name, :email, :gender, :birthday,
    :address, :zip_code, :town, :country,
    :additional_information,
    :phone_numbers_attributes,

    # Custom attrs
    :newsletter,
    :promocode,
    :privacy_policy_accepted,

    # Internal attrs
    :primary_group_id,
    :household_key
  ]

  self.required_attrs = [
    :first_name, :last_name, :email, :address, :zip_code, :town, :birthday
  ]

  attr_accessor(*attrs)
  delegate :phone_numbers, :gender_label, :privacy_policy_accepted?, to: :person
  validate :assert_privacy_policy

  def person
    Person.new(attributes.except(:newsletter, :promocode)).tap do |p|
      p.tag_list.add  "newsletter" if attributes[:newsletter]
      p.tag_list.add "promocode" if attributes[:promocode]
    end
  end

  private

  def assert_privacy_policy
    if privacy_policy_accepted&.to_i&.zero?
      message = I18n.t('groups.self_registration.create.flash.privacy_policy_not_accepted')
      errors.add(:base, message)
    end
  end
end
