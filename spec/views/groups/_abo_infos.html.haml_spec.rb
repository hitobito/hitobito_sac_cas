#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "groups/self_registration/_abo_infos.html.haml" do
  let(:costs) do
    [OpenStruct.new(amount: 60, country: :switzerland),
      OpenStruct.new(amount: 76, country: :international)]
  end

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before { allow(view).to receive(:costs).and_return(costs) }

  it "renders subscription duration info" do
    expect(dom).to have_text "Preis pro Jahr"
    expect(dom).to have_text "CHF 60 inkl. MwSt."
    expect(dom).to have_text "CHF 76 inkl. MwSt."
    expect(dom).to have_text "Versandsland"
    expect(dom).to have_text "Schweiz"
    expect(dom).to have_text "Weltweit"
  end

  it "renders duration info" do
    expect(dom).to have_text "Dauer und Erneuerung des Abonnements"
    expect(dom).to have_text "Das Abonnement kann jederzeit zum Ende der laufenden Periode gekündigt werden."
  end
end
