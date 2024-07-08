# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person sac remarks" do
  let(:person) { people(:mitglied) }
  let(:group) { person.groups.first }

  before do
    person.roles.create!(
      group: groups(:geschaeftsstelle),
      type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
    )
    sign_in(person)
  end

  it "lists and updates sac remarks" do
    visit group_person_sac_remarks_path(:de, group, person)

    within("#sac_remark_national_office") do
      click_link
      fill_in "person_sac_remark_national_office", with: "my remark"
      click_button
    end

    expect(page).to have_text("my remark")
    expect(person.reload.sac_remark_national_office).to eq("my remark")
  end
end
