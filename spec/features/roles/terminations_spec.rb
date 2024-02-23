# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe :roles_terminations, js: true do
  def visit_dialog(role)
    sign_in(role.person)
    visit history_group_person_path(group_id: role.group_id, id: role.person_id)
    click_link(href: /#{new_group_role_termination_path(group_id: role.group_id, role_id: role.id)}/)

    # wait for modal to appear before we continue
    expect(page).to have_selector('#role-termination.modal')
  end

  it 'lists all affected roles' do
    # when terminating the hauptsektion role, the affected roles include
    # all zusatzektion roles as well
    visit_dialog(roles(:mitglied))

    within('.modal-dialog') do
      expect(page).to have_content "SAC Blüemlisalp / Mitglieder / Mitglied (Stammsektion) (Einzel)" # roles(:mitglied)
      expect(page).to have_content "SAC Matterhorn / Mitglieder / Mitglied (Zusatzsektion) (Einzel)" # roles(:mitglied_zusatzsektion)
    end
  end

  it 'mentions the role person' do
    visit_dialog(roles(:mitglied))

    within('.modal-dialog') do
      expect(page).to have_content /Austritt.*#{roles(:mitglied).person.full_name}/
    end
  end

  it 'mentions the affected people' do
    # when terminating the hauptsektion role of a family member, the affected people
    # include all family members
    visit_dialog(roles(:familienmitglied))

    within('.modal-dialog') do
      expect(page).to have_content /sowie für.*#{people(:familienmitglied2).full_name}/
      expect(page).to have_content /sowie für.*#{people(:familienmitglied_kind).full_name}/
    end
  end
end
