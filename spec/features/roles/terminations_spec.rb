# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe :roles_terminations, js: true do
  let(:role) { roles(:abonnent_alpen) }

  def visit_dialog
    sign_in(people(:admin))
    visit history_group_person_path(group_id: role.group_id, id: role.person_id)
    click_link(href: /#{new_group_role_termination_path(group_id: role.group_id, role_id: role.id)}/)

    # wait for modal to appear before we continue
    expect(page).to have_selector("#role-termination.modal")
  end

  it "lists affected role and mentions person" do
    # when terminating the stammsektion role, the affected roles include
    # all zusatzektion roles as well
    visit_dialog

    within(".modal-dialog") do
      expect(page).to have_content "SAC/CAS / Die Alpen DE / Abonnent" # roles(:mitglied)
      expect(page).to have_content(/Austritt.*#{roles(:abonnent_alpen).person.full_name}/)
    end
  end

  it "displays disabled button with tooltip when current_user is abonnent" do
    sign_in(role.person)
    visit history_group_person_path(group_id: role.group_id, id: role.person_id)

    expect(page).to have_css 'button[disabled="disabled"]', text: "Austritt"
    expect(page).to have_css('div[rel="tooltip"][title="Eine Kündigung kann nur über den Mitgliederdienst des SAC erfolgen. Bitte schreibe eine E-Mail mit dem gewünschten Kündigungstermin sowie deinem Vor- und Nachnamen an mv@sac-cas.ch."]')
  end
end
