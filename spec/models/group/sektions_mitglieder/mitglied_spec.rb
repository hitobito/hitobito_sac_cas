# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "../shared_examples_mitglied"

describe Group::SektionsMitglieder::Mitglied do
  it_behaves_like "validates Mitglied active period"

  context "#create" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { Fabricate(:person, household_key: 4242, birthday: 10.years.ago) }

    it "sets family_id from household_key for family membership" do
      role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person:, group:)
      expect(role.beitragskategorie).to be_family
      expect(role.family_id).to eq "4242"
      expect(role.reload.family_id).to eq "4242"
    end

    it "does not set family_id if already set" do
      role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person:, group:,
        family_id: "F1234")
      expect(role.family_id).to eq "F1234"
      expect(role.reload.family_id).to eq "F1234"
    end

    [:adult, :youth].each do |beitragskategorie|
      it "does not set family_id for #{beitragskategorie}" do
        role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person:, group:, beitragskategorie: beitragskategorie)
        expect(role.beitragskategorie).to eq beitragskategorie.to_s
        expect(role.family_id).to be_nil
        expect(role.reload.family_id).to be_nil
      end
    end
  end

  context "household" do
    let(:familienmitglied) { roles(:familienmitglied) }
    let(:familienmitglied2) { roles(:familienmitglied2) }

    context "as main person" do
      it "destroys household" do
        expect { familienmitglied.destroy }.to change { familienmitglied.person.reload.sac_family_main_person }.from(true).to(false)
          .and change { familienmitglied.person.reload.primary_group }.from(groups(:bluemlisalp_mitglieder)).to(groups(:matterhorn_mitglieder))
      end

      it "does not destroy household when skip_destroy_household is set" do
        familienmitglied.skip_destroy_household = true

        expect { familienmitglied.destroy }.to not_change { familienmitglied.person.reload.sac_family_main_person }
          .and not_change { familienmitglied.person.household_key }
      end
    end

    context "as not main person" do
      it "leaves household" do
        expect { familienmitglied2.destroy }
          .to not_change { familienmitglied.person.reload.sac_family_main_person }
          .and not_change { Household.new(familienmitglied.person).empty? }
      end

      it "does not leave household when skip_destroy_household is set" do
        familienmitglied2.skip_destroy_household = true
        expect { familienmitglied2.destroy }
          .to not_change { familienmitglied.person.reload.sac_family_main_person }
          .and not_change { familienmitglied.person.household_key }
      end
    end
  end

  describe "#transmit_data_to_abacus" do
    let(:person) do
      people(:mitglied).tap do |person|
        person.phone_numbers.create!(number: "+41791234567", label: "mobile")
        person.roles.destroy_all
      end
    end

    subject(:create_role) do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:bluemlisalp_mitglieder),
        start_on: Time.zone.now,
        end_on: Time.zone.tomorrow
      )
    end

    it "enqueues the job" do
      expect { create_role }.to change(Delayed::Job, :count).by(1)
    end

    it "doesn't enqueue the job if the abacus subject key is set" do
      person.update!(abacus_subject_key: person.id)
      expect { create_role }.not_to change(Delayed::Job, :count)
    end

    it "doesn't enqueue the job if data quality errors exist" do
      allow(person).to receive(:data_quality).and_return("error")
      expect { create_role }.not_to change(Delayed::Job, :count)
    end
  end
end
