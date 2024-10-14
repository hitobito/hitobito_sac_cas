# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::Member do
  let(:root) { Group.root }
  let(:person) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }

  subject do
    # member expects preloaded roles (without them it would not respect the date in the default roles scope)
    person_with_roles = context.people_with_membership_years.find(person.id)
    described_class.new(person_with_roles, context)
  end

  before do
    Role.update_all(end_on: date.end_of_year)
    travel_to date - 1.month
  end

  context "main methods" do
    before do
      Group::SektionsMitglieder::Ehrenmitglied.create!(
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        start_on: "2022-08-01"
      )
    end

    it { expect(subject.age).to eq(date.year - person.birthday.year) }
    it { expect(subject.stammsektion_role).to eq(roles(:mitglied)) }
    it { expect(subject.zusatzsektion_roles).to eq([roles(:mitglied_zweitsektion)]) }
    it { expect(subject.sac_ehrenmitglied?).to be_falsey }
    it { expect(subject.sac_magazine?).to be_truthy }
    it { expect(subject.sac_family_main_person?).to be_falsey }
    it { expect(subject.living_abroad?).to be_falsey }
    it { expect(subject.sektion_ehrenmitglied?(groups(:bluemlisalp))).to be_truthy }
    it { expect(subject.sektion_ehrenmitglied?(groups(:matterhorn))).to be_falsey }
    it { expect(subject.sektion_beguenstigt?(groups(:bluemlisalp))).to be_falsey }
  end

  context "#membership years" do
    let(:person) { context.people_with_membership_years.find(people(:mitglied).id) }

    it "counts years correctly" do
      roles(:mitglied).update_column(:start_on, "2015-01-01")
      expect(subject.membership_years).to eq(8)
    end

    it "is off by one in first year" do
      roles(:mitglied).update_column(:start_on, date)
      expect(subject.membership_years).to eq(1)
    end
  end

  context "#paying_person?" do
    it { expect(subject.paying_person?(subject.stammsektion_role.beitragskategorie)).to be(true) }

    context "for family member" do
      let(:person) { people(:familienmitglied2) }

      it { expect(subject.paying_person?(subject.stammsektion_role.beitragskategorie)).to be(false) }

      it "is true for additional section" do
        role = Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          start_on: "2022-08-01",
          beitragskategorie: :adult,
          end_on: "2023-12-31"
        )
        expect(subject.paying_person?(role.beitragskategorie)).to be(true)
      end
    end
  end

  context "#household_people" do
    let(:familienmitglied) { people(:familienmitglied) }
    let(:familienmitglied2) { people(:familienmitglied2) }
    let(:familienmitglied_kind) { people(:familienmitglied_kind) }

    subject { described_class.new(familienmitglied, context) }

    context "year 2023" do
      it "returns all active household people" do
        expect(subject.family_members).to contain_exactly(familienmitglied2, familienmitglied_kind)
      end
    end

    context "in the future" do
      let(:date) { Date.new(Time.zone.today.year + 2, 1, 1) }

      it "does not return all people" do
        familienmitglied2.roles.each { |role| role.update_column(:end_on, Date.yesterday) }
        familienmitglied_kind.roles.each { |role| role.update_column(:end_on, Date.yesterday) }
        expect(subject.family_members).not_to include(familienmitglied2, familienmitglied_kind)
      end
    end
  end
end
