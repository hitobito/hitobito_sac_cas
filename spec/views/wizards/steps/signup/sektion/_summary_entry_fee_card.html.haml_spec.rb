#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/signup/sektion/_summary_entry_fee_card.html.haml" do
  include FormatHelper

  let(:wizard) { Wizards::Signup::SektionWizard.new(group: groups(:bluemlisalp_neuanmeldungen_nv), person_fields: {birthday: 30.years.ago.to_date}) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(wizard: wizard)
  end

  it "renders summary card with discount information" do
    travel_to(Date.new(2024, 10, 11)) do
      expect(dom).to have_css(".well div:nth-of-type(1).fw-bold.h6", text: "Sektion SAC Blüemlisalp")
      expect(dom).to have_css(".well div:nth-of-type(2) dt", text: "CHF 127.00")
      expect(dom).to have_css(".well div:nth-of-type(2) dd", text: "jährlicher Beitrag")
      expect(dom).to have_css(".well div:nth-of-type(3) dt", text: "CHF 127.00")
      expect(dom).to have_css(".well div:nth-of-type(3) dd", text: "- 100% Rabatt auf den jährlichen Beitrag")
      expect(dom).to have_css(".well div:nth-of-type(4) dt", text: "CHF 20.00")
      expect(dom).to have_css(".well div:nth-of-type(4) dd", text: "+ einmalige Eintrittsgebühr")
      expect(dom).to have_css(".well div:nth-of-type(5) dt", text: "CHF 20.00")
      expect(dom).to have_css(".well div:nth-of-type(5) dd", text: "Total erstmalig")
    end
  end

  it "renders summary card without discount information" do
    travel_to(Date.new(2024, 3, 11)) do
      expect(dom).to have_css(".well div:nth-of-type(1).fw-bold.h6", text: "Sektion SAC Blüemlisalp")
      expect(dom).to have_css(".well div:nth-of-type(2) dt", text: "CHF 127.00")
      expect(dom).to have_css(".well div:nth-of-type(2) dd", text: "jährlicher Beitrag")
      expect(dom).to have_css(".well div:nth-of-type(3) dt", text: "CHF 20.00")
      expect(dom).to have_css(".well div:nth-of-type(3) dd", text: "+ einmalige Eintrittsgebühr")
      expect(dom).to have_css(".well div:nth-of-type(4) dt", text: "CHF 147.00")
      expect(dom).to have_css(".well div:nth-of-type(4) dd", text: "Total erstmalig")
    end
  end
end
