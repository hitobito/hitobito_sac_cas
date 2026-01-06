# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Migrations::ProcessLeftOverMembershipInvoicesFrom2025 do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
  let(:person) { neuanmeldung.person }

  def create_invoice(year: 2025, state: :payed, updated_at: Time.zone.local(2026, 1, 5, 14))
    Fabricate(:sac_membership_invoice, person:, link: group, year:, state:, updated_at:)
  end

  subject(:job) { described_class.new }

  let(:end_of_25) { Date.new(2025, 12, 31) }

  before { travel_to(Time.zone.local(2026, 1, 6)) }

  context "stammsektion" do
    let(:neuanmeldung) do
      person = Fabricate(:person, birthday: Time.zone.today - 19.years, confirmed_at: nil)
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
        person: person,
        beitragskategorie: :adult,
        group:)
    end

    it "creates ended mitglied role for invoice from 2025 payed in 2026" do
      create_invoice
      expect { job.perform }.to change { person.roles.ended.count }.by(1)
      stammsektion_role = person.roles.ended.first
      expect(stammsektion_role.start_on).to eq end_of_25
      expect(stammsektion_role.end_on).to eq end_of_25
    end

    it "noops for open invoice from 2025" do
      create_invoice(state: :open)
      expect { job.perform }.not_to change { person.roles.count }
    end

    it "noops for payed invoice from 2026" do
      create_invoice(year: 2026)
      expect { job.perform }.not_to change { person.roles.count }
    end

    it "noops for if already converted" do
      neuanmeldung.destroy!
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person: person, group: groups(:bluemlisalp_mitglieder))
      create_invoice
      expect { job.perform }.not_to change { person.roles.count }
    end
  end

  context "zusatzsektion" do
    let(:person) { Fabricate(:person, birthday: Time.zone.today - 19.years, confirmed_at: nil) }
    let(:neuanmeldung) do
      Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name.to_sym,
        person: person,
        beitragskategorie: :adult,
        group:)
    end

    before do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person:, group: groups(:matterhorn_mitglieder),
        start_on: Date.new(2025, 1, 1))
      neuanmeldung
    end

    it "creates ended mitglied role for invoice from 2025 payed in 2026" do
      create_invoice
      expect { job.perform }.to change { person.roles.ended.count }.by(1)
      zusatzsektion_role = person.roles.ended.first
      expect(zusatzsektion_role.start_on).to eq end_of_25
      expect(zusatzsektion_role.end_on).to eq end_of_25
    end

    it "noops for open invoice from 2025" do
      create_invoice(state: :open)
      expect { job.perform }.not_to change { person.roles.count }
    end

    it "noops for payed invoice from 2026" do
      create_invoice(year: 2026)
      expect { job.perform }.not_to change { person.roles.count }
    end

    it "noops for if already converted" do
      neuanmeldung.destroy!
      Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, person: person,
        group: groups(:bluemlisalp_mitglieder))
      create_invoice
      expect { job.perform }.not_to change { person.roles.count }
    end
  end
end
