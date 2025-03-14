# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "people/external_invoices/_actions_index.html.haml" do
  subject { Capybara::Node::Simple.new(render) }

  describe "create membership invoice button" do
    before do
      assign(:group, groups(:bluemlisalp_mitglieder))
      assign(:person, people(:mitglied))
      allow(view).to receive(:can?).with(:create_membership_invoice, people(:mitglied)).and_return(true)
      allow(view).to receive(:can?).with(:create_abo_magazin_invoice, people(:mitglied)).and_return(true)
      allow(people(:mitglied)).to receive(:sac_membership_invoice?).and_return(true)
    end

    it "renders membership invoice button when invoice is possible" do
      expect(subject).to have_text "Mitgliedschaftsrechnung erstellen"
    end

    it "does not render membership invoice button when no permission" do
      allow(view).to receive(:can?).with(:create_membership_invoice, people(:mitglied)).and_return(false)

      expect(subject).to have_no_text "Mitgliedschaftsrechnung erstellen"
    end

    it "does not render membership invoice button when invoice is not possible for person" do
      allow(people(:mitglied)).to receive(:sac_membership_invoice?).and_return(false)

      expect(subject).to have_no_text "Mitgliedschaftsrechnung erstellen"
    end
  end

  describe "create abo magazin invoice button" do
    let(:person) { people(:abonnent) }

    before do
      assign(:group, groups(:abo_die_alpen))
      assign(:person, person)
      allow(view).to receive(:can?).with(:create_abo_magazin_invoice, person).and_return(true)
    end

    it "renders abo magazin invoice button when person has active abonnent role" do
      expect(subject).to have_text "Die Alpen Rechnung erstellen"
    end

    it "renders abo magazin invoice button when person has inactive abonnent role with end on less than 11 months ago" do
      person.roles.first.update_column(:end_on, 6.months.ago)
      expect(subject).to have_text "Die Alpen Rechnung erstellen"
    end

    it "renders abo magazin invoice button when person has neuanmeldung role" do
      person.roles.destroy_all
      Fabricate(Group::AboMagazin::Neuanmeldung.sti_name, person: person, group: groups(:abo_die_alpen), start_on: 1.day.ago, end_on: 20.days.from_now)
      expect(subject).to have_text "Die Alpen Rechnung erstellen"
    end

    it "does not render abo magazin when person has inactive abonnent role with end on over 11 months ago" do
      person.roles.first.update_column(:end_on, 1.year.ago)
      expect(subject).to have_no_text "Die Alpen Rechnung erstellen"
    end

    it "does not render abo magazin when person does not have any role related to abo" do
      person.roles.destroy_all
      expect(subject).to have_no_text "Die Alpen Rechnung erstellen"
    end

    it "does not render abo magazin when no permission" do
      allow(view).to receive(:can?).with(:create_abo_magazin_invoice, person).and_return(false)

      expect(subject).to have_no_text "Die Alpen Rechnung erstellen"
    end
  end
end
