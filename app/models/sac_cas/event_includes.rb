# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::EventIncludes
  # This module is included instead of prepended, which is required for some overrides.

  extend ActiveSupport::Concern

  included do
    self.possible_contact_attrs = [:first_name, :last_name, :email, :address_care_of, :street,
      :housenumber, :postbox, :zip_code, :town, :country, :gender, :birthday,
      :phone_number_mobile, :phone_number_landline]
    self.mandatory_contact_attrs = [:email, :first_name, :last_name, :birthday, :street,
      :housenumber, :zip_code, :town, :country]
  end
end
