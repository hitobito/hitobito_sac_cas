# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SelfRegistration::InfosComponent, type: :component do
  subject(:component) { described_class.new }

  subject(:html) { render_inline(component) }

  subject(:parts) { html.css("aside.card .card-body") }

  it "does render" do
    expect(component).to be_render
  end

  describe "general" do
    subject(:body) { parts[0] }

    it "renders title" do
      expect(body).to have_css("h2.card-title", text: "Fragen zur Mitgliedschaft?")
    end

    it "info text with link to faqs" do
      expect(body).to have_css("p.card-text", text: "Mehr Informationen findest du unter den FAQs")
      expect(body).to have_link("FAQs", href: "https://www.sac-cas.ch/de/meta/faq/mitgliedschaft")
    end
  end

  describe "contact" do
    subject(:body) { parts[1] }

    it "renders title" do
      expect(body).to have_css("h2.card-title", text: "Kontakt")
    end

    it "renders address" do
      expect(body).to have_content <<~TEXT
        Schweizer Alpen-Club SAC
        Monbijoustrasse 61
        3000 Bern 14
        Tel: +41 31 370 18 18
        #{SacCas::MV_EMAIL}
      TEXT
    end

    it "renders phone number as link" do
      expect(body).to have_link("+41 31 370 18 18", href: "tel:+41313701818")
    end

    it "does render email as link" do
      expect(body).to have_link(SacCas::MV_EMAIL)
    end
  end

  describe "membership" do
    subject(:body) { parts[2] }

    it "renders title" do
      expect(body).to have_css("h2.card-title", text: "Möchtest du SAC-Mitglied werden?")
    end

    it "renders link to membership signup" do
      expect(body).to have_link "Jetzt Mitgliedschaft beantragen",
        href: "https://www.sac-cas.ch/de/mitgliedschaft/mitglied-werden/"
    end
  end

  describe "documents" do
    subject(:body) { parts[3] }

    it "renders title" do
      expect(body).to have_css("h2.card-title", text: "Dokumente")
    end

    it "renders link to statutes" do
      expect(body).to have_link "Statuten", href: "https://www.sac-cas.ch/fileadmin/Spezial/SAC-Mitgliedschaft/DE/SAC_Statuten_A5_DE.pdf"
    end

    it "renders link to contributation regulations" do
      expect(body).to have_link "Beitragsreglement", href: "https://www.sac-cas.ch/fileadmin/Spezial/SAC-Mitgliedschaft/DE/Beitragsreglement.pdf"
    end

    it "renders link to data protection" do
      expect(body).to have_link "Datenschutzerklärung", href: "https://www.sac-cas.ch/de/meta/datenschutz"
    end
  end
end
