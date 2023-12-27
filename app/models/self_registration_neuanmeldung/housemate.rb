# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::Housemate < SelfRegistrationNeuanmeldung::Person
  self.required_attrs = [
    :first_name, :last_name, :email, :birthday
  ]

  self.attrs = required_attrs + [
    :gender, :primary_group, :household_key, :_destroy, :household_emails, :supplements
  ]

  def person
    @person ||= Person.new(attributes.except('_destroy', 'household_emails',
                                             'supplements')).tap do |p|
      p.privacy_policy_accepted_at = Time.zone.now if supplements&.links_present?
    end
  end
end
