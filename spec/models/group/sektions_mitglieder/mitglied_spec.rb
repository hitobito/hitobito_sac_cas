# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "../shared_examples_mitglied"

describe Group::SektionsMitglieder::Mitglied do
  it_behaves_like "validates Mitglied timestamps"

  context "household" do
    let(:familienmitglied) { roles(:familienmitglied) }
    let(:familienmitglied2) { roles(:familienmitglied2) }

    it "does destroy household if main person" do
      expect do
        familienmitglied.destroy
      end.to change { familienmitglied.person.reload.sac_family_main_person }.from(true).to(false)
        .and change { Household.new(familienmitglied.person).empty? }.from(false).to(true)
        .and change { familienmitglied.person.reload.primary_group }.from(groups(:bluemlisalp_mitglieder)).to(groups(:matterhorn_mitglieder))
    end

    it "leaves household as as if not main person" do
      expect do
        familienmitglied2.destroy
      end.to not_change { familienmitglied.person.reload.sac_family_main_person }
        .and not_change { Household.new(familienmitglied.person).empty? }
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
        delete_on: Time.zone.tomorrow,
        created_at: Time.zone.now
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
      person.update!(first_name: nil)
      expect { create_role }.not_to change(Delayed::Job, :count)
    end
  end
end
