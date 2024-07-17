# frozen_string_literal: true

#
#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/kinds/_form.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:kind) { Event::Kind.new }

  before do
    assign(:qualification_kinds, [])
    assign(:prolongations, [])
    assign(:preconditions, [])
    assign(:kind_categories, [])
    assign(:course_compensation_categories, [])
    allow(view).to receive_messages(entry: kind, model_class: Event::Kind, path_args: [kind])
  end

  it "renders additional fields" do
    expect(dom).to have_field "Unterkunft reservieren durch SAC"
    expect(dom).to have_select "Unterkunft"
    expect(dom).to have_select "Kostenstelle"
    expect(dom).to have_select "Kostenträger"
    expect(dom).to have_text "Vergütungskategorien"
    expect(dom).to have_select "Saison"
    expect(dom).to have_field "Ausbildungstage"
    expect(dom).to have_field "Minimale Teilnehmerzahl"
    expect(dom).to have_field "Maximale Teilnehmerzahl"
  end
end
