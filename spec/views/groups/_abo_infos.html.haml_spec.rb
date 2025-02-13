#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "groups/self_registration/_abo_infos.html.haml" do
  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(view).to receive_messages(wizard: wizard)
    Group.root.update!(abo_alpen_fee: 60, abo_alpen_postage_abroad: 16, abo_touren_portal_fee: 50)
  end

  context "abo magazin wizard" do
    let(:wizard) { Wizards::Signup::AboMagazinWizard.new(group: groups(:abo_die_alpen)) }

    it "renders subscription pricing info" do
      expect(dom).to have_text "Preis pro Jahr"
      expect(dom).to have_text "CHF 60 inkl. MwSt."
      expect(dom).to have_text "Versandsland"
      expect(dom).to have_text "Schweiz"
    end

    it "does not count liechtenstein as international shipping" do
      wizard.person_fields.country = "LI"
      expect(dom).to have_text "Preis pro Jahr"
      expect(dom).to have_text "CHF 60 inkl. MwSt."
      expect(dom).to have_text "Versandsland"
      expect(dom).to have_text "Schweiz"
    end

    it "renders duration info" do
      expect(dom).to have_text "Dauer und Erneuerung des Abonnements"
      expect(dom).to have_text "Das Abonnement kann jederzeit zum Ende der laufenden Periode gekündigt werden."
    end

    context "international" do
      before do
        wizard.person_fields.country = "DE"
      end

      it "renders subscription pricing info" do
        expect(dom).to have_text "Preis pro Jahr"
        expect(dom).to have_text "CHF 76 inkl. MwSt."
        expect(dom).to have_text "Versandsland"
        expect(dom).to have_text "Weltweit"
      end
    end
  end

  context "abo touren portal wizard" do
    let(:wizard) { Wizards::Signup::AboTourenPortalWizard.new(group: groups(:abo_die_alpen)) }

    it "renders subscription pricing info" do
      expect(dom).to have_text "Preis pro Jahr"
      expect(dom).to have_text "CHF 50 inkl. MwSt."
      expect(dom).not_to have_text "Versandsland"
    end
  end
end
