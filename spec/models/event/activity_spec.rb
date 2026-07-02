# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Activity do
  let(:main_activity) { event_activities(:wandern) }
  let(:child_activity) { event_activities(:wanderweg) }

  it ".list orders entries" do
    expect(main_activity.children.list)
      .to eq(event_activities(:wanderweg, :bergtour, :schneeschuh))
  end

  it ".main only returns parents" do
    expect(described_class.main)
      .to match_array(event_activities(:wandern, :hochtour, :klettern))
  end

  context "create" do
    it "enqueues CreateApprovalCommissionResponsibilitiesJob for main" do
      expect do
        Fabricate(:event_activity)
      end.to change {
        Delayed::Job.where("handler like '%Event::CreateApprovalCommissionResponsibilitiesJob%'").count
      }
    end

    it "does not enqueue CreateApprovalCommissionResponsibilitiesJob for sub" do
      expect do
        Fabricate(:event_activity, parent: event_activities(:wandern))
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
      entry.label = "Wintersport"
      entry.description = "Beschreibung"
      expect(entry).to be_valid
    end

    it "prevent children as parents" do
      entry = Fabricate.build(:event_activity, parent: child_activity)
      expect(entry).not_to be_valid
      expect(entry.errors.details[:parent_id]).to eq [error: :parent_is_not_main]
    end

    it "validates format of color" do
      entry = described_class.new
      entry.label = "Wintersport"
      entry.description = "Beschreibung"
      entry.color = "invalid"
      expect(entry).not_to be_valid
      expect(entry.errors.full_messages).to eq(
        ["Farbe muss ein zulässiger 6-stelliger Hexadezimal Wert beginnend mit # sein"]
      )
      entry.color = "#AACCFF"
      expect(entry).to be_valid
      entry.color = "#aaccff"
      expect(entry).to be_valid
      entry.color = "#abc"
      expect(entry).not_to be_valid
    end
  end

  context ".assignable" do
    before do
      main_activity.children.update_all(deleted_at: Time.zone.now)
      main_activity.update(deleted_at: Time.zone.now)
    end

    it "contains no soft deleted entries" do
      expect(described_class.assignable.count).to eq(described_class.without_deleted.count)
      expect(described_class.assignable).not_to include(child_activity)
    end

    it "contains entries for passed ids even if they are not soft deleted" do
      activity = event_activities(:felsklettern)
      expect(described_class.assignable(activity.id)).to include(activity)
      expect(described_class.assignable.count).to eq(described_class.without_deleted.count)
    end

    it "contains entries for passed ids even if they are soft deleted" do
      expect(described_class.assignable(child_activity.id)).to include(child_activity)
      expect(described_class.assignable(main_activity.children.pluck(:id)).count).to eq(described_class.count)
      expect(described_class.assignable(main_activity.id)).to include(main_activity)
    end

    it "contains parents for passed ids even if they are soft deleted" do
      expect(described_class.assignable(child_activity.id)).to include(main_activity)
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { event_activities(:indoorklettern).destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::Activity::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      expect { child_activity.destroy }
        .to change { described_class.unscoped.count }.by(0)
        .and change { Event::Activity::Translation.count }.by(0)
      expect(child_activity.deleted_at).to be_present
      expect(child_activity.translations).to be_present
    end

    it "prevents delete if children exist" do
      expect { main_activity.destroy }.not_to change { described_class.unscoped.count }
      expect(main_activity.errors.details[:base]).to eq [error: :has_children]
      expect(main_activity.deleted_at).to be_nil
    end

    it "soft deletes if children are all deleted" do
      event_activities(:skihochtour).update!(deleted_at: Time.zone.now)
      event_activities(:snowboardhochtour).update!(deleted_at: Time.zone.now)
      expect { event_activities(:hochtour).destroy }
        .not_to change { described_class.unscoped.count }
      expect(event_activities(:hochtour).deleted_at).to be_present
    end

    it "deletes event_approval_commission_responsibilities on destroy" do
      event_activities(:klettern).children.destroy_all
      expect { event_activities(:klettern).destroy }.to change { Event::ApprovalCommissionResponsibility.count }
    end

    it "does not delete event_approval_commission_responsibilities on soft destroy" do
      expect { event_activities(:klettern).destroy }.not_to change { Event::ApprovalCommissionResponsibility.count }
    end
  end
end
