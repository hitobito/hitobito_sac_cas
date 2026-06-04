# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participations/tours/_signup_aside.html.haml" do
  include FormatHelper

  let(:tour) { events(:section_tour) }
  let(:contact) { people(:admin) }

  before do
    allow(view).to receive_messages(price: 50)
    assign(:event, tour.decorate)
  end

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  it "has event contact information" do
    expect(dom).to have_css "h2.card-title", text: "Kontakt"
    expect(dom).to have_text "Anna Admin"
    expect(dom).to have_text "Ophovenerstrasse 79a"
    expect(dom).to have_text "support@hitobito.example.com"
  end

  it "does not render contact person attributes excluded in visible_contact_attributes" do
    tour.update!(visible_contact_attributes: ["name"])

    expect(dom).not_to have_text "support@hitobito.example.com"
  end

  it "does not render contact card for tour without contact" do
    tour.update!(contact: nil)

    expect(dom).not_to have_css "h2.card-title", text: "Kontakt"
  end

  it "does render tour price" do
    expect(dom).to have_css "h2.card-title", text: "Kosten"
    expect(dom).to have_css "td", text: "Total"
    expect(dom).to have_css "td", text: "50"
  end
end
