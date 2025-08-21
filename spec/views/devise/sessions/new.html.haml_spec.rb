#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "devise/sessions/new.html.haml" do
  subject(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  let(:group) { groups(:abo_basic_login) }

  before do
    allow(view).to receive(:resource).and_return(Person.new)
  end

  it "does render custom helpful links" do
    render
    expect(dom).to have_link "Passwort vergessen", href: new_person_password_path
    expect(dom).to have_link "Keine Bestätigungs-E-Mail bekommen?", href: new_person_confirmation_path
    expect(dom).to have_link "Kein SAC-Mitglied? Jetzt dein kostenloses SAC-Konto erstellen", href: group_self_registration_path(group)
    expect(dom).to have_link "SAC Mitgliedschaft beantragen", href: "https://www.sac-cas.ch/de/mitgliedschaft/mitglied-werden/"
  end

  describe "oauth" do
    before { params[:oauth] = "true" }

    it "does render custom helpful links" do
      render
      expect(dom).to have_text "Bitte melde dich an, um weiter zu gelangen."
      expect(dom).to have_link "Passwort vergessen", href: new_person_password_path
      expect(dom).to have_link "Keine Bestätigungs-E-Mail bekommen?", href: new_person_confirmation_path
      expect(dom).to have_link "Kein SAC-Mitglied? Jetzt dein kostenloses SAC-Konto erstellen", href: group_self_registration_path(group)
      expect(dom).to have_link "SAC Mitgliedschaft beantragen", href: "https://www.sac-cas.ch/de/mitgliedschaft/mitglied-werden/"
    end
  end
end
