# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::CreateApprovalCommissionResponsibilitiesJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new(discipline:, target_group:, freigabe_komitee_group:) }

  let(:discipline) { nil }
  let(:target_group) { nil }
  let(:freigabe_komitee_group) { nil }

  let(:bluemlisalp_freigabekomitee) { groups(:bluemlisalp_freigabekomitee) }
  let(:matterhorn_touren_und_kurse) {
    Fabricate(Group::SektionsTourenUndKurse.sti_name.to_sym, name: "Touren und Kurse Matterhorn",
      parent: groups(:matterhorn_funktionaere))
  }
  let(:first_matterhorn_freigabekomitee) {
    Fabricate(Group::FreigabeKomitee.sti_name.to_sym, name: "FreigabeKomitee Matterhorn",
      parent: matterhorn_touren_und_kurse)
  }
  let(:main_disciplines) { Event::Discipline.main.list }
  let(:main_target_groups) { Event::TargetGroup.main.list }

  context "#initialize" do
    it "must receive exactly one argument" do
      expect do
        described_class.new
      end.to raise_error("must pass exactly one argument")

      expect do
        described_class.new(freigabe_komitee_group: first_matterhorn_freigabekomitee,
          discipline: Fabricate(:event_discipline))
      end.to raise_error("must pass exactly one argument")
    end
  end

  context "first freigabe_komitee_group given" do
    let(:freigabe_komitee_group) { first_matterhorn_freigabekomitee }
    let(:expected_count) { 36 } # 3 main disciplines * 6 main target_groups * 2 subito options * 1 freigabe_komitee

    it "creates commission responsibilities for each combination" do
      expect do
        job.perform
      end.to change { Event::ApprovalCommissionResponsibility.count }.by(expected_count)

      expect_all_combinations_to_be_covered
    end
  end

  context "with multiple layers with a freigabekomitee" do
    before do
      described_class.new(freigabe_komitee_group: first_matterhorn_freigabekomitee).perform
    end

    context "discipline given" do
      let(:discipline) { Fabricate(:event_discipline) }
      let(:expected_count) { 24 } # 1 main discipline * 6 main target_groups * 2 subito options * 2 freigabe_komitees

      it "creates commission responsibilities for each combination" do
        expect do
          job.perform
        end.to change { Event::ApprovalCommissionResponsibility.count }.by(expected_count)

        expect_all_combinations_to_be_covered
      end

      it "picks freigabekomitee with most commission responsibilities" do
        second_freigabe_komitee = Fabricate(Group::FreigabeKomitee.sti_name.to_sym, name: "Zweites Freigabekomitee",
          parent: groups(:bluemlisalp_touren_und_kurse))

        expect do
          job.perform
        end.to change { Event::ApprovalCommissionResponsibility.count }.by(expected_count)
          .and change {
                 bluemlisalp_freigabekomitee.reload.event_approval_commission_responsibilities.count
               }.by(expected_count / 2)
          .and change {
                 first_matterhorn_freigabekomitee.reload.event_approval_commission_responsibilities.count
               }.by(expected_count / 2)

        expect(second_freigabe_komitee.reload.event_approval_commission_responsibilities.count).to eq(0)
      end
    end

    context "target_group given" do
      let(:target_group) { Fabricate(:event_target_group) }
      let(:expected_count) { 12 } # 3 main disciplines * 1 main target_group * 2 subito options * 2 freigabe_komitees

      it "creates commission responsibilities for each combination" do
        expect do
          job.perform
        end.to change { Event::ApprovalCommissionResponsibility.count }.by(expected_count)

        expect_all_combinations_to_be_covered
      end

      it "picks freigabekomitee with most commission responsibilities" do
        second_freigabe_komitee = Fabricate(Group::FreigabeKomitee.sti_name.to_sym, name: "Zweites Freigabekomitee",
          parent: groups(:bluemlisalp_touren_und_kurse))

        expect do
          job.perform
        end.to change { Event::ApprovalCommissionResponsibility.count }.by(expected_count)
          .and change {
                 bluemlisalp_freigabekomitee.reload.event_approval_commission_responsibilities.count
               }.by(expected_count / 2)
          .and change {
                 first_matterhorn_freigabekomitee.reload.event_approval_commission_responsibilities.count
               }.by(expected_count / 2)

        expect(second_freigabe_komitee.reload.event_approval_commission_responsibilities.count).to eq(0)
      end
    end
  end

  def expect_all_combinations_to_be_covered
    Group.where(type: [Group::Sektion, Group::Ortsgruppe].map(&:sti_name))
      .where(id: Group::FreigabeKomitee.select(:layer_group_id)).each do |sektion_or_ortsgruppe|
        main_disciplines.each do |discipline|
          main_target_groups.each do |target_group|
            [true, false].each do |subito|
              approval_commission_responsibility = Event::ApprovalCommissionResponsibility.where(
                sektion: sektion_or_ortsgruppe,
                discipline:,
                target_group:,
                subito:
              )
              expect(approval_commission_responsibility).to be_present
            end
          end
        end
      end
  end
end
