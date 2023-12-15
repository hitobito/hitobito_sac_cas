# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::MainPerson < SelfRegistration::Person

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
    :primary_group,
    :household_key
  ]

  self.required_attrs = [
    :first_name, :last_name, :email, :address, :zip_code, :town, :birthday, :country
  ]

  delegate  :salutation_label, :phone_numbers, :privacy_policy_accepted?, to: :person
  validate :assert_privacy_policy
  validate :assert_phone_number

  attr_accessor :step

  def self.model_name
    ActiveModel::Name.new(SelfRegistration::MainPerson, nil)
  end

  def self.human_attribute_name(*args)
    return PhoneNumber.model_name.human if args.first =~ /phone_numbers/

    super
  end

  def person
    @person ||= Person.new(attributes.except('newsletter', 'promocode').compact).tap do |p|
      p.tag_list.add 'newsletter' if attributes['newsletter']
      p.tag_list.add 'promocode' if attributes['promocode']
      p.phone_numbers.build(label: 'Privat') if p.phone_numbers.empty?
    end
  end

  private

  def assert_phone_number
    errors.add(:phone_numbers, :blank) if phone_numbers.none?(&:valid?)
  end

  def assert_privacy_policy
    if privacy_policy_accepted&.to_i&.zero?
      message = I18n.t('groups.self_registration.create.flash.privacy_policy_not_accepted')
      errors.add(:base, message)
    end
  end
end
