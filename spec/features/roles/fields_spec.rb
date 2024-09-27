# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "roles/_fields.html.haml" do
  before do
    sign_in(people(:admin))
    visit edit_group_role_path(group_id: role.group_id, id: role.id)
  end

  context "wizard managed role" do
    let(:role) { roles(:mitglied) }

    it "doesn't show 'Von' field" do
      expect(page).to have_text("Daten")
      expect(page).not_to have_field("Von")
    end
  end

  context "other role" do
    let(:role) { roles(:abonnent_alpen) }

    it "shows 'Von' field" do
      expect(page).to have_text("Daten")
      expect(page).to have_field("Von")
    end
  end
end
