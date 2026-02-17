# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::TargetGroup do
  let(:main_group) { event_target_groups(:senioren) }
  let(:child_group) { event_target_groups(:senioren_b) }

  it ".list orders entries" do
    expect(main_group.children.list)
      .to eq(event_target_groups(:senioren_a, :senioren_b, :senioren_c))
  end

  it ".main only returns parents" do
    expect(described_class.main)
      .to eq(event_target_groups(:kinder, :jugend, :jung_erwachsene, :erwachsene, :senioren, :familien))
  end

  context "create" do
    it "enqueues CreateApprovalCommissionResponsibilitiesJob" do
      expect do
        Fabricate(:event_target_group)
      end.to change {
        Delayed::Job.where("handler like '%Event::CreateApprovalCommissionResponsibilitiesJob%'").count
      }
    end

    it "does not enqueue CreateApprovalCommissionResponsibilitiesJob for sub" do
      expect do
        Fabricate(:event_target_group, parent: event_target_groups(:kinder))
      end.to_not change {
        Delayed::Job.where("handler like '%Event::CreateApprovalCommissionResponsibilitiesJob%'").count
      }
    end
  end

  context "validations" do
    it "require presence of label" do
      entry = described_class.new
      expect(entry).not_to be_valid
      expect(entry.errors[:label]).to eq ["muss ausgefüllt werden"]
      entry.label = "Jungs"
      entry.description = "Boys only"
      expect(entry).to be_valid
    end

    it "prevent children as parents" do
      entry = Fabricate.build(:event_target_group, parent: child_group)
      expect(entry).not_to be_valid
      expect(entry.errors.details[:parent_id]).to eq [error: :parent_is_not_main]
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { event_target_groups(:jung_erwachsene).destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::TargetGroup::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      group = events(:section_tour).target_groups.first
      expect { group.destroy }
        .to change { described_class.unscoped.count }.by(0)
        .and change { Event::TargetGroup::Translation.count }.by(0)
      expect(group.deleted_at).to be_present
      expect(group.translations).to be_present
    end

    it "prevents delete if children exist" do
      expect { main_group.destroy }.not_to change { described_class.unscoped.count }
      expect(main_group.errors.details[:base]).to eq [error: :has_children]
      expect(main_group.deleted_at).to be_nil
    end

    it "soft deletes if children are all deleted" do
      %w[a b c].each do |letter|
        event_target_groups("senioren_#{letter}").update!(deleted_at: Time.zone.now)
      end
      expect { main_group.destroy }
        .not_to change { described_class.unscoped.count }
      expect(main_group.deleted_at).to be_present
    end

    it "deletes event_approval_commission_responsibilities on destroy" do
      event_target_groups(:jugend).children.destroy_all
      expect { event_target_groups(:jugend).destroy }.to change { Event::ApprovalCommissionResponsibility.count }
    end

    it "does not delete event_approval_commission_responsibilities on soft destroy" do
      expect { event_target_groups(:senioren).destroy }.not_to change { Event::ApprovalCommissionResponsibility.count }
    end
  end
end
