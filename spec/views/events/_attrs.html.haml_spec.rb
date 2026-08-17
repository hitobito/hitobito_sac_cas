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

    before do
      allow(view).to receive(:course?).and_return(false)
      allow(view).to receive(:tour?).and_return(false)
    end

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
    let(:event) { Fabricate.build(:course, minimum_age: 10, canceled_reason: :weather) }

    before do
      allow(view).to receive(:course?).and_return(true)
      allow(view).to receive(:tour?).and_return(false)
    end

    it "renders additional attrs" do
      expect(dom).to have_css ".well dl:nth-of-type(2) dt", text: "Kursstufe"
      expect(dom).to have_css ".well dl:nth-of-type(2) dt", text: "Saison"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Unterkunft"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Sprache"
      expect(dom).to have_css ".well dl:nth-of-type(5) dt", text: "Kursbeginn"
      expect(dom).to have_css "aside dt", text: "Mindestalter"
      expect(dom).to have_css "aside dt", text: "Absagegrund"
    end
  end

  context "Event::Tour" do
    let(:event) { events(:section_tour) }

    before do
      event.subito = true
      assign(:group, groups(:bluemlisalp))
      allow(view).to receive(:course?).and_return(false)
      allow(view).to receive(:tour?).and_return(true)
    end

    it "renders additional attrs" do
      expect(dom).to have_css ".well dt", text: "Gipfel"
      expect(dom).to have_css ".well dt", text: "Auf-/Abstieg (Hm)"
      expect(dom).to have_css ".well dt", text: "Link zum Tourenportal"
      expect(dom).to have_css ".well dt", text: "Zeitaufwand"
      expect(dom).to have_css ".well dt", text: "Zeitaufwand"
      expect(dom).to have_css ".well dt", text: "Karten"
      expect(dom).to have_css ".well dt", text: "Alternativroute"
      expect(dom).to have_css ".well dt", text: "Zusatzinfo"
      expect(dom).to have_css "aside dt", text: "Ist Subito-Tour"
    end

    it "renders minimum and maximum_age regardless of other conditions" do
      event.update!(application_conditions: nil, minimum_age: 10, maximum_age: 80)

      expect(dom).to have_css "dt", text: "Mindestalter"
      expect(dom).to have_css "dt", text: "Maximalalter"
    end

    context "Freigabestufe" do
      let(:komitee) { groups(:bluemlisalp_freigabekomitee) }

      def approve(kind)
        event.approvals.create!(
          approval_kind: event_approval_kinds(kind),
          approved: true,
          freigabe_komitee: komitee,
          creator: people(:admin)
        )
      end

      it "shows the next pending approval level below the status" do
        expect(dom).to have_css "dt", text: "Freigabestufe"
        expect(dom).to have_css "dd div", text: /\AFachlich\z/
      end

      it "hides the line when the tour is not in review" do
        event.update!(state: :draft)
        expect(dom).not_to have_css "dt", text: "Freigabestufe"
      end

      it "hides the line when all approval levels are approved" do
        approve(:professional)
        approve(:security)
        approve(:editorial)
        expect(dom).not_to have_css "dt", text: "Freigabestufe"
      end

      context "with multiple responsible komitees" do
        let!(:second_komitee) do
          Group::FreigabeKomitee.create!(
            name: "Zweitkomitee",
            parent: groups(:bluemlisalp_touren_und_kurse)
          )
        end

        before do
          event_approval_commission_responsibilities(:bluemlisalp_wandern_familien_subito)
            .update!(freigabe_komitee: second_komitee)
        end

        it "shows the komitee name in parentheses per komitee" do
          expect(dom).to have_css "dd div", text: /\AFachlich \(Zweitkomitee\)\z/
          expect(dom).to have_css "dd div", text: /\AFachlich \(Freigabekomitee\)\z/
        end

        it "keeps the komitee name when only one komitee still has a pending level" do
          approve(:professional)
          approve(:security)
          approve(:editorial)
          expect(dom).to have_css "dd div", text: /\AFachlich \(Zweitkomitee\)\z/
          expect(dom).not_to have_css "dd div", text: /\AFachlich \(Freigabekomitee\)\z/
        end
      end
    end
  end
end
