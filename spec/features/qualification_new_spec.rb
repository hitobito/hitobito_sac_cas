# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "qualification new", js: true do
  let(:person) { people(:admin) }

  before { sign_in(person) }

  it "toggles finish_at depending on qualification kind" do
    qualification_kind_with_validity = Fabricate(:qualification_kind, validity: 2)
    qualification_kind_without_validity = Fabricate(:qualification_kind, validity: nil)

    visit new_group_person_qualification_path(group_id: person.primary_group_id, person_id: person.id)

    expect(page).to have_no_field "qualification_finish_at"

    select qualification_kind_without_validity.label, from: "qualification_qualification_kind_id"
    expect(page).to have_select("qualification_qualification_kind_id", selected: qualification_kind_without_validity.label)

    expect(page).to have_field "Bis"

    select qualification_kind_with_validity.label, from: "qualification_qualification_kind_id"
    expect(page).to have_select("qualification_qualification_kind_id", selected: qualification_kind_with_validity.label)

    expect(page).to have_no_field "qualification_finish_at"
  end
end
