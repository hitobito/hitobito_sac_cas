#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/signup/sektion/_summary_entry_fee_card.html.haml" do
  include FormatHelper

  let(:wizard) { Wizards::Signup::SektionWizard.new(group: groups(:bluemlisalp_neuanmeldungen_nv)) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
 

  before do
    allow(view).to receive_messages(wizard: wizard)
  end


  it "renders summary card with all information" do
    expect(dom).to have_css('.fw-bold.h6', text:  "Sektion SAC Blüemlisalp")
    expect(dom).to have_text "CHF 122 - jährlicher Beitrag"
    expect(dom).to have_text "CHF 30 - einmalige Gebühr"
    expect(dom).to have_css('.fw-bold', text:  "CHF 152 - Total")
  end
end
