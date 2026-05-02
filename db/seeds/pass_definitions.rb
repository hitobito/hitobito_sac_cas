# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

sac_group = Group::SacCas.first!

PassDefinition.find_or_create_by!(
  owner: sac_group,
  template_key: "sac_membership"
) do |pd|
  pd.name = "SAC Mitgliederausweis"
  pd.description = "Mitgliederausweis des Schweizer Alpen-Clubs"

  grant = pd.pass_grants.build(grantor: sac_group)

  # Rollentypen die zur Berechtigung führen
  SacCas::MITGLIED_STAMMSEKTION_ROLES.each do |role_type|
    grant.related_role_types.build(role_type: role_type.sti_name)
  end
end
