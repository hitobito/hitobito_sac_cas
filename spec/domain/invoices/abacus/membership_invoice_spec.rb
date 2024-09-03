# frozen_string_literal: true

require "spec_helper"

describe Invoices::Abacus::MembershipInvoice do
  let(:root) { Group.root }
  let(:person) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }
  let(:member) { Invoices::SacMemberships::Member.new(person, context) }
  let(:memberships) { member.active_memberships }

  subject do
    # member expects preloaded roles (without them it would not respect the date in the default roles scope)
    ActiveRecord::Associations::Preloader.new.preload([person], :roles, Role.active(context.date))
    # our specs expect roles to be present, check this precondition after preloading
    assert person.roles.present?
    described_class.new(member, memberships)
  end

  before do
    Role.update_all(end_on: date.end_of_year)
  end

  context "#invoice?" do
    it { expect(subject.invoice?).to be(true) }

    context "for family member" do
      let(:person) { people(:familienmitglied2) }

      it { expect(subject.invoice?).to be(false) }

      it "is true with additional section" do
        Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          start_on: "2022-08-01",
          beitragskategorie: :adult,
          end_on: "2023-12-31"
        )
        expect(subject.invoice?).to be(true)
      end
    end
  end

  context "#membership_cards?" do
    it { expect(subject.membership_cards?).to be(true) }

    context "with new additional membership" do
      let(:additional_role) do
        Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.create!(
          person: person,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          start_on: "2022-08-01"
        )
      end
      let(:memberships) { [member.membership_from_role(additional_role)] }

      it "is false with new additional section" do
        expect(subject.membership_cards?).to be(false)
      end
    end

    context "for family member" do
      let(:person) { people(:familienmitglied2) }

      it { expect(subject.membership_cards?).to be(false) }

      it "is false with additional section" do
        Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
          person: person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          start_on: "2022-08-01",
          beitragskategorie: :adult,
          end_on: "2023-12-31"
        )
        expect(subject.membership_cards?).to be(false)
      end
    end
  end
end
