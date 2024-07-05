#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "events/_attrs.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:person) { Person.new }

  before do
    allow(view).to receive_messages(entry: EventDecorator.decorate(event))
    allow(controller).to receive_messages(current_user: person)
    allow(controller).to receive_messages(current_person: person)
  end

  context "event" do
    let(:event) { Fabricate.build(:event) }

    it "hides additional attrs" do
      expect(dom).not_to have_css "dl dt", text: "Kursstufe"
      expect(dom).not_to have_css "dl dt", text: "Saison"
      expect(dom).not_to have_css "dl dt", text: "Unterkunft"
      expect(dom).not_to have_css "dl dt", text: "Sprache"
      expect(dom).not_to have_css "dl dt", text: "Kursbeginn"
      expect(dom).not_to have_css "dl dt", text: "Mindestalter"
    end
  end

  context "Event::Course" do
    let(:event) { Fabricate.build(:course) }

    it "renders additional attrs" do
      expect(dom).to have_css ".well dl:nth-of-type(2) dt", text: "Kursstufe"
      expect(dom).to have_css ".well dl:nth-of-type(2) dt", text: "Saison"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Unterkunft"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Sprache"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Kursbeginn"
      expect(dom).to have_css "aside dt", text: "Mindestalter"
    end
  end
end
