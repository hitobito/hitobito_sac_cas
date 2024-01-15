# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::SelfRegistration::Housemate
  extend ActiveSupport::Concern

  prepended do
    self.attrs = [
      :first_name, :last_name, :gender, :birthday, :additional_email, :phone_number,
      :primary_group, :household_key, :_destroy, :household_emails
    ]

    self.required_attrs = [
      :first_name, :last_name, :gender, :birthday
    ]
  end

  def person
    @person ||= Person.new(attributes.except('_destroy', 'household_emails', 'additional_email', 'phone_number')).tap do |p|
      p.additional_emails.build(additional_email_attributes)
      p.phone_numbers.build(phone_number_attributes)
    end
  end

  def additional_email_attributes
    {label: 'Privat', email: additional_email}
  end

  def phone_number_attributes
    {label: 'Haupt-Telefon', number: phone_number}
  end
end
