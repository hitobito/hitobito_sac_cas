# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "group show page" do
  let(:admin) { people(:admin) }
  let(:sektion) { groups(:bluemlisalp) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  describe "sac self registration link" do
    before { sign_in(admin) }

    it "shows link" do
      visit group_path(id: sektion.id)

      expect(page).to have_css("a", text: /http:\/\/.+\/groups\/#{neuanmeldungen_sektion.id}\/self_registration/)
    end
  end

  describe "section offering" do
    before { sign_in(admin) }

    it "shows section offers" do
      sektion.section_offerings = [SectionOffering.create!(title: "Offer 1"), SectionOffering.create!(title: "Offer 2")]
      visit group_path(id: sektion.id)

      expect(page).to have_css("dt", text: "Sektionsangebote")
      expect(page).to have_css("dt", text: "Offer 1")
      expect(page).to have_css("dt", text: "Offer 2")
    end
  end
end
