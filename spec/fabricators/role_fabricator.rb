# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# Mitglied roles in SAC are required to have a created_at/activate_on and a deleted_at/delete_on
# We set these attributes here in the factory to a default value, so we don't have to do it all the time
# in the specs.
Role.all_types.select {|role| role < SacCas::Role::MitgliedCommon }.each do |role|
  name = role.name.to_sym
  Fabrication.manager[name].append_or_update_attribute(:created_at, nil) { Time.current }
  Fabrication.manager[name].append_or_update_attribute(:delete_on, nil) { Time.zone.today.end_of_year.to_date }
end
