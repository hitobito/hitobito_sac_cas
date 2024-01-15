# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::SelfRegistration::Housemate
  extend ActiveSupport::Concern

  prepended do
    self.attrs = [
      :first_name, :last_name, :gender, :birthday,
      :primary_group, :household_key, :_destroy, :household_emails
    ]

    self.required_attrs = [
      :first_name, :last_name, :gender, :birthday
    ]
  end
end
