#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/signup/_section_fee_summary.html.haml" do
  include FormatHelper
  let(:group) { groups(:bluemlisalp) }
  let(:adult) { fees_for(:adult) }
  let(:family) { fees_for(:family) }
  let(:youth) { fees_for(:youth) }

  let(:dom) {
    Capybara::Node::Simple.new(@rendered)
  }

  def fees_for(beitragskategorie)
    Invoices::SacMemberships::SectionSignupFeePresenter.new(group, Person.new(sac_family_main_person: true), beitragskategorie, date: Time.zone.now.beginning_of_year)
  end

  it "is hidden if not active" do
    render locals: {adult:, family:, youth:, active: false}
    expect(dom).to have_css "aside.card.d-none"
  end

  it "is hidden if not active" do
    render locals: {adult:, family:, youth:, active: true}
    expect(dom).to have_css "aside.card:not(.d-none)"
  end

  it "renders label and amount" do
    render locals: {adult:, family:, youth:, active: true}
    expect(dom).to have_css "tr:nth-of-type(1) td:nth-of-type(1)", text: "Einzelmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(1) td:nth-of-type(2)", text: "CHF 127.00 + einmalige Eintrittsgebühr CHF 20.00"
    expect(dom).to have_css "tr:nth-of-type(2) td:nth-of-type(1)", text: "Familienmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(2) td:nth-of-type(2)", text: "CHF 179.00 + einmalige Eintrittsgebühr CHF 35.00"
    expect(dom).to have_css "tr:nth-of-type(3) td:nth-of-type(1)", text: "Jugendmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(3) td:nth-of-type(2)", text: "CHF 76.00 + einmalige Eintrittsgebühr CHF 15.00"
  end

  it "renders label and amount without entry fee" do
    render locals: {adult:, family:, youth:, active: true, skip_entry_fee: true}
    expect(dom).to have_css "tr:nth-of-type(1) td:nth-of-type(1)", text: "Einzelmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(1) td:nth-of-type(2)", text: "CHF 127.00"
    expect(dom).to have_css "tr:nth-of-type(2) td:nth-of-type(1)", text: "Familienmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(2) td:nth-of-type(2)", text: "CHF 179.00"
    expect(dom).to have_css "tr:nth-of-type(3) td:nth-of-type(1)", text: "Jugendmitgliedschaft"
    expect(dom).to have_css "tr:nth-of-type(3) td:nth-of-type(2)", text: "CHF 76.00"
  end
end
