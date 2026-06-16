# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::SektionsfunktionaereMailer do
  let(:person) { people(:mitglied) }
  let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
  let(:touren_und_kurse) { groups(:bluemlisalp_touren_und_kurse) }
  let(:huetten_group) {
    Fabricate(Group::SektionsClubhuette.sti_name,
      parent: Fabricate(Group::SektionsClubhuetten.sti_name, parent: groups(:bluemlisalp_funktionaere)))
  }

  before do
    Group.root.update!(course_admin_email: "course@coursecourse.course")
  end

  shared_examples "onboarding mail" do |method, bcc|
    subject(:mail) { described_class.send(method, role) }

    it "sends to person email" do
      expect(mail.to).to eq([person.email])
    end

    it "should have bcc #{bcc}" do
      expect(mail.bcc).to eq([bcc])
    end
  end

  describe "#praesidium_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Praesidium.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :praesidium_onboarding, SacCas::MV_EMAIL
  end

  describe "#mitgliederverwaltung_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Mitgliederverwaltung.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :mitgliederverwaltung_onboarding, SacCas::MV_EMAIL
  end

  describe "#administration_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Administration.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :administration_onboarding, SacCas::MV_EMAIL
  end

  describe "#redaktion_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Redaktion.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :redaktion_onboarding, SacCas::MV_EMAIL
  end

  describe "#kulturbeauftragter_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Kulturbeauftragter.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :kulturbeauftragter_onboarding, SacCas::MV_EMAIL
  end

  describe "#umweltbeauftragter_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Umweltbeauftragter.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :umweltbeauftragter_onboarding, SacCas::MV_EMAIL
  end

  describe "#huettenobmann_onboarding" do
    let(:role) { Group::SektionsFunktionaere::Huettenobmann.new(person:, group: funktionaere) }

    it_behaves_like "onboarding mail", :huettenobmann_onboarding, SacCas::HUETTEN_EMAIL
  end

  describe "#tourenchef_onboarding" do
    let(:role) { Group::SektionsTourenUndKurse::Tourenchef.new(person:, group: touren_und_kurse) }

    it_behaves_like "onboarding mail", :tourenchef_onboarding, "course@coursecourse.course"
  end

  describe "#tourenleiter_onboarding" do
    let(:role) { Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.new(person:, group: touren_und_kurse) }

    it_behaves_like "onboarding mail", :tourenleiter_onboarding, "course@coursecourse.course"
  end

  describe "#kibe_chef_onboarding" do
    let(:role) { Group::SektionsTourenUndKurse::KibeChef.new(person:, group: touren_und_kurse) }

    it_behaves_like "onboarding mail", :kibe_chef_onboarding, SacCas::JUGEND_EMAIL
  end

  describe "#fabe_chef_onboarding" do
    let(:role) { Group::SektionsTourenUndKurse::FabeChef.new(person:, group: touren_und_kurse) }

    it_behaves_like "onboarding mail", :fabe_chef_onboarding, SacCas::JUGEND_EMAIL
  end

  describe "#jo_chef_onboarding" do
    let(:role) { Group::SektionsTourenUndKurse::JoChef.new(person:, group: touren_und_kurse) }

    it_behaves_like "onboarding mail", :jo_chef_onboarding, SacCas::JUGEND_EMAIL
  end

  describe "#huettenchef_onboarding" do
    let(:role) { Group::SektionsClubhuette::Huettenchef.new(person:, group: huetten_group) }

    it_behaves_like "onboarding mail", :huettenchef_onboarding, SacCas::HUETTEN_EMAIL
  end

  describe "#huettenwart_onboarding" do
    let(:role) { Group::SektionsClubhuette::Huettenwart.new(person:, group: huetten_group) }

    it_behaves_like "onboarding mail", :huettenwart_onboarding, SacCas::HUETTEN_EMAIL
  end
end
