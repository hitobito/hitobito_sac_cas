# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Invoices::Abacus::MembershipInvoiceGenerator do
  let(:section) { bluemlisalp }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }

  let(:reference_date) { now }
  let(:now) { Time.zone.local(2024, 8, 24, 1) }

  before { travel_to(now) }

  subject(:generator) { described_class.new(person.id, section, reference_date) }

  context "for mitglied" do
    let(:person) { people(:mitglied) }

    # TODO - smells wrong, shouldnt we only be billing stammsektion here?
    it "returns both stammsektion and zusatzsektion memberships" do
      invoice = generator.build
      expect(invoice.memberships).to have(2).items
      expect(invoice.memberships.map(&:section)).to match_array [bluemlisalp, matterhorn]
    end

    it "includes zusatzsektion if destroyed" do
      roles(:mitglied_zweitsektion).destroy
      invoice = generator.build
      expect(invoice.memberships).to have(2).items
      expect(invoice.memberships.map(&:section)).to match_array [bluemlisalp, matterhorn]
    end

    it "excludes zusatzsektion if deleted" do
      Role.where(id: roles(:mitglied_zweitsektion).id).delete_all
      invoice = generator.build
      expect(invoice.memberships).to have(1).items
      expect(invoice.memberships.map(&:section)).to match_array [bluemlisalp]
    end

    context "for zusatzsektion" do
      let(:section) { matterhorn }

      it "includes only zusatzsektion" do
        invoice = generator.build
        expect(invoice.memberships).to have(1).items
        expect(invoice.memberships.map(&:section)).to match_array [matterhorn]
      end
    end
  end

  context "for neuanmeldung_nv sektion" do
    let(:person) {
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.name,
        group: groups(:bluemlisalp_neuanmeldungen_nv),
        created_at: Time.zone.now.beginning_of_year,
        delete_on: Time.zone.today.end_of_year).person
    }

    it "returns invoice single memberships" do
      invoice = generator.build
      expect(invoice.memberships).to have(1).item
      expect(invoice.memberships.map(&:section)).to match_array [bluemlisalp]
    end
  end
end
