# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::MainPerson < SelfRegistrationNeuanmeldung::Person
  self.attrs = [
    :first_name, :last_name, :email, :gender, :birthday,
    :address, :zip_code, :town, :country,
    :additional_information,
    :phone_numbers_attributes,

    # Internal attrs
    :primary_group,
    :household_key,
    :supplements
  ]

  self.required_attrs = [
    :first_name, :last_name, :email, :address, :zip_code, :town, :birthday, :country
  ]

  delegate :newsletter, :self_registration_reason_id, to: :supplements, allow_nil: true
  delegate :salutation_label, :phone_numbers, to: :person

  validate :assert_phone_number

  def self.model_name
    ActiveModel::Name.new(SelfRegistration::MainPerson, nil)
  end

  def initialize(*args)
    super
    self.country ||= Settings.addresses.imported_countries.to_a.first
  end

  def save!
    super.then do |success|
      exclude_from_mailing_list if success && mailing_list && !newsletter
    end
  end

  def person # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
    @person ||= Person.new(attributes.compact.except('supplements')).tap do |p|
      p.phone_numbers.build(label: 'Privat') if p.phone_numbers.empty?
      p.self_registration_reason_id = self_registration_reason_id
      p.privacy_policy_accepted_at = Time.zone.now if supplements&.sektion_statuten

      p.tag_list.add 'newsletter' if newsletter
    end
  end

  private

  def assert_phone_number
    errors.add(:phone_numbers, :blank) if phone_numbers.none?(&:valid?)
  end

  def exclude_from_mailing_list
    mailing_list.subscriptions.create!(subscriber: person, excluded: true)
  end

  def mailing_list
    @mailing_list ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
  end
end
