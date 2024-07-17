# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::Member do
  let(:root) { Group.root }
  let(:person) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }

  subject { described_class.new(person, context) }

  before do
    Role.update_all(delete_on: date.end_of_year)
    Group::SektionsMitglieder::Ehrenmitglied.create!(
      person: person,
      group: groups(:bluemlisalp_mitglieder),
      created_at: "2022-08-01"
    )
  end

  it { expect(subject.age).to eq(date.year - person.birthday.year) }
  it { expect(subject.main_membership_role).to eq(roles(:mitglied)) }
  it { expect(subject.additional_membership_roles).to eq([roles(:mitglied_zweitsektion)]) }
  it { expect(subject.sac_honorary_member?).to be_falsey }
  it { expect(subject.sac_magazine?).to be_truthy }
  it { expect(subject.sac_family_main_person?).to be_falsey }
  it { expect(subject.living_abroad?).to be_falsey }
  it { expect(subject.section_honorary_member?(groups(:bluemlisalp))).to be_truthy }
  it { expect(subject.section_honorary_member?(groups(:matterhorn))).to be_falsey }
  it { expect(subject.section_benefited_member?(groups(:bluemlisalp))).to be_falsey }

  context "#membership years" do
    let(:person) { Person.with_membership_years("people.*", date).find_by(id: people(:mitglied).id) }

    it { expect(subject.membership_years).to eq(8) }
  end

  context "#paying_person?" do
    it { expect(subject.paying_person?(subject.main_membership_role.beitragskategorie)).to be(true) }

    context "for family member" do
      let(:person) { people(:familienmitglied2) }

      it { expect(subject.paying_person?(subject.main_membership_role.beitragskategorie)).to be(false) }

      it "is true for additional section" do
        role = Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          created_at: "2022-08-01",
          beitragskategorie: :adult,
          delete_on: "2023-12-31"
        )
        expect(subject.paying_person?(role.beitragskategorie)).to be(true)
      end
    end
  end
end
