# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::Housemate < SelfRegistrationNeuanmeldung::Person

  NON_ASSIGNABLE_ATTRIBUTES = %w(
    household_emails
    supplements
    additional_email
    phone_number
    _destroy
  ).freeze

  self.required_attrs = [
    :first_name, :last_name, :email, :birthday
  ]

  self.attrs = required_attrs + [
    :gender, :additional_email, :phone_number,
    :primary_group, :household_key, :_destroy, :household_emails, :supplements
  ]


  def person
    @person ||= Person.new(attributes.except(*NON_ASSIGNABLE_ATTRIBUTES)).tap do |p|
      p.privacy_policy_accepted_at = Time.zone.now if supplements&.links_present?

      with_value_for(:additional_email) do |value|
        p.email = value
        p.additional_emails.build(email: value, label: 'Privat')
      end
      with_value_for(:phone_number) do |value|
        p.phone_numbers.build(number: value, label: 'Haupt-Telefon')
      end
    end
  end

  private

  def with_value_for(key)
    value = attributes[key.to_s]
    yield value if value.present?
  end
end
