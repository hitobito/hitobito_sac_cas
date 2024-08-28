# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people invoices page" do
  let(:admin) { people(:admin) }

  before { sign_in(admin) }

  context "no issues" do
    it "doesnt shows an alert" do
      visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id, person_id: admin.id)
      expect(page).not_to have_css(".alert-danger")
    end
  end

  context "data quality issues" do
    before { admin.update!(first_name: nil) }

    it "shows an alert message" do
      visit new_group_person_membership_invoice_path(group_id: admin.groups.first.id, person_id: admin.id)
      expect(page).to have_css(".alert-danger", text: "Vorname ist leer")
    end
  end
end
