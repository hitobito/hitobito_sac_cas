# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApprovalCommissionResponsibilityForm do
  let(:group) { groups(:bluemlisalp) }
  let(:group_responsibilities) { group.event_approval_commission_responsibilities }

  subject(:event_approval_commission_responsibility_form) { described_class.new(group:) }

  describe "#event_approval_commission_responsibilities" do
    it "returns all event_approval_commission_responsibilities of current sektion" do
      expect(subject.event_approval_commission_responsibilities).to match_array group_responsibilities
    end

    it "builds new entries when combination doesn't exist" do
      missing_respponsibility = group.event_approval_commission_responsibilities.last.destroy
      new_record = subject.event_approval_commission_responsibilities.select { _1.id.nil? }.first

      expect(subject.event_approval_commission_responsibilities).not_to match_array group_responsibilities.reload
      expect(new_record.target_group_id).to eq missing_respponsibility.target_group_id
      expect(new_record.discipline_id).to eq missing_respponsibility.discipline_id
      expect(new_record.subito).to eq missing_respponsibility.subito
      expect(new_record.sektion_id).to eq missing_respponsibility.sektion_id
    end
  end

  describe "#grouped_event_approval_commission_responsibilities" do
    it "groups entries by target_group and discipline" do
      responsibility_1 = instance_double(Event::ApprovalCommissionResponsibility, target_group: "Youth",
        discipline: "Eating")
      responsibility_2 = instance_double(Event::ApprovalCommissionResponsibility, target_group: "Youth",
        discipline: "Sleeping")
      responsibility_3 = instance_double(Event::ApprovalCommissionResponsibility, target_group: "Adult",
        discipline: "Sleeping")
      allow(subject).to receive(:event_approval_commission_responsibilities).and_return([responsibility_1,
        responsibility_2, responsibility_3])

      expect(subject.grouped_event_approval_commission_responsibilities).to eq({
        "Youth" => {
          "Eating" => [responsibility_1],
          "Sleeping" => [responsibility_2]
        },
        "Adult" => {
          "Sleeping" => [responsibility_3]
        }
      })
    end
  end

  describe "#valid?" do
    it "checks approvals and copies errors to form" do
      subject.event_approval_commission_responsibilities.first.freigabe_komitee_id = nil
      subject.event_approval_commission_responsibilities.second.freigabe_komitee_id = nil
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq [
        "Kinder (KiBe) - Wandern: Freigabekomitee muss ausgefüllt werden",
        "Kinder (KiBe) - Wandern: Freigabekomitee muss ausgefüllt werden"
      ]
    end
  end

  describe "#save!" do
    it "updates the records" do
      new_freigabe_komitee = Group::FreigabeKomitee.create!(name: "Freigabekomitee",
        parent: groups(:bluemlisalp_touren_und_kurse))
      updated_id = subject.event_approval_commission_responsibilities.first.id
      subject.event_approval_commission_responsibilities.first.freigabe_komitee = new_freigabe_komitee
      subject.save!
      expect(group.reload.event_approval_commission_responsibilities
                         .find(updated_id)
                         .freigabe_komitee).to eq new_freigabe_komitee
    end

    it "saves new records" do
      group.event_approval_commission_responsibilities.last.destroy
      subject.event_approval_commission_responsibilities.select { _1.id.nil? }
        .first
        .freigabe_komitee_id = groups(:bluemlisalp_freigabekomitee).id

      expect {
        subject.save!
      }.to change { Event::ApprovalCommissionResponsibility.count }.by(1)
    end

    it "fails if invalid" do
      subject.event_approval_commission_responsibilities.first.freigabe_komitee_id = nil
      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
