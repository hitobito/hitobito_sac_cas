#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "events/_form.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:group) { Group.new(id: 1) }

  before do
    assign(:group, group)
    assign(:kinds, [])
    allow(view).to receive_messages(path_args: [group, event], entry: event.decorate,
      model_class: Event)
  end

  context "event" do
    let(:event) { Fabricate.build(:event) }

    it "hides additional fields" do
      expect(dom).not_to have_field "Unterkunft reservieren durch SAC"
      expect(dom).not_to have_select "Unterkunft"
      expect(dom).not_to have_select "Sprache"
      expect(dom).not_to have_select "Kostenstelle"
      expect(dom).not_to have_select "Kostenträger"
      expect(dom).not_to have_checked_field "Jährlich wiederkehrend"
      expect(dom).not_to have_field "Link Teilnehmer"
      expect(dom).not_to have_field "Link Kurskader"
      expect(dom).not_to have_field "Link Umfrage"
      expect(dom).not_to have_select "Saison"
      expect(dom).not_to have_select "Kursbeginn"
      expect(dom).not_to have_field "Mindestalter"
    end
  end

  context "Event::Course" do
    let(:event) { Fabricate.build(:course) }

    it "renders additional fields" do
      expect(dom).to have_field "Unterkunft reservieren durch SAC"
      expect(dom).to have_select "Unterkunft"
      expect(dom).to have_select "Sprache"
      expect(dom).to have_select "Kostenstelle"
      expect(dom).to have_select "Kostenträger"
      expect(dom).to have_checked_field "Jährlich wiederkehrend"
      expect(dom).to have_field "Link Teilnehmer"
      expect(dom).to have_field "Link Kurskader"
      expect(dom).to have_field "Link Umfrage"
      expect(dom).to have_select "Saison"
      expect(dom).to have_select "Kursbeginn"
      expect(dom).to have_field "Mindestalter"
    end
  end

  context "Event::Tour" do
    let(:event) { events(:section_tour) }

    before do
      assign(:disciplines, [])
      assign(:target_groups, [])
      assign(:fitness_requirements, [])
      assign(:technical_requirements, [])
      assign(:traits, [])
    end

    it "renders additional fields" do
      expect(dom).to have_field "Gipfel"
      expect(dom).to have_field "Aufstieg"
      expect(dom).to have_field "Abstieg"
      expect(dom).to have_field "Saison"
      expect(dom).to have_field "Interne Bemerkungen"
      expect(dom).to have_field "Mindestalter"
      expect(dom).to have_field "Maximalalter"
      expect(dom).to have_field "Link zum Tourenportal"
      expect(dom).to have_field "Ist Subito-Tour"
    end
  end
end
