# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistrationAboBasic::MainPerson < SelfRegistrationAbo::Person
  self.attrs = [
    :first_name, :last_name, :email, :gender, :birthday,
    :address, :zip_code, :town, :country,
    :number,
    :primary_group
  ]

  self.required_attrs = [
    :first_name, :last_name, :email, :birthday
  ]
end
