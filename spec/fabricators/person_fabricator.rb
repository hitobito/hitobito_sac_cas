# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# People in SAC are required to be older than 6 years, so we make sure they have such a birthday
Fabrication.manager[:person].append_or_update_attribute(:birthday, nil) { 24.years.ago }
# Nickname is not used, so set it nil
Fabrication.manager[:person].append_or_update_attribute(:nickname, nil)

# Mitglied roles in SAC are required to have a street, housenumber, zip_code and town
Fabrication.manager[:person].append_or_update_attribute(:street, nil) { "Ophovenerstrasse" }
Fabrication.manager[:person].append_or_update_attribute(:housenumber, nil) { "79a" }
Fabrication.manager[:person].append_or_update_attribute(:zip_code, nil) { "2843" }
Fabrication.manager[:person].append_or_update_attribute(:town, nil) { "Neu Carlscheid" }

Fabrication.manager[:person].append_or_update_attribute(:data_retention_consent, nil) { true }

# Make sure to update the cached membership years after creating a person
Fabrication.manager[:person].callbacks[:after_create] ||= []
Fabrication.manager[:person].callbacks[:after_create] << lambda do |person, _transients|
  Person.with_membership_years.find(person.id).update_cached_membership_years!
end
