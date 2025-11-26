# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe :roles_terminations, js: true do
  let(:role) { roles(:abonnent_alpen) }

  it "renders link to terminate abonnent path" do
    sign_in(role.person)
    visit history_group_person_path(group_id: role.group_id, id: role.person_id)
    link = page.find_link "Austritt"
    expect(link[:href]).to match group_person_role_terminate_abo_magazin_abonnent_path(group_id: role.group_id,
      person_id: role.person_id, role_id: role.id)
  end
end
