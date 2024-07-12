#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people/membership/verify/_member_details_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before { allow(view).to receive_messages(person: person) }

  context "member" do
    let(:person) { people(:mitglied) }

    it "hides tour guide info" do
      expect(dom).not_to have_text "Aktive/r Tourenleiter/in"
    end
  end

  context "tour guide" do
    let(:person) { people(:mitglied) }

    it "renders tour guide info for active tour guide" do
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: 1.month.ago
      )
      person.roles.create!(
        type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
        group: groups(:matterhorn_touren_und_kurse)
      )

      expect(dom).to have_text "Aktive/r Tourenleiter/in"
    end
  end
end
