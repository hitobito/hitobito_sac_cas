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
    it "is valid" do
      expect(main_activity).to be_valid
    end

    it "requires presence of label" do
      main_activity.label = nil

      expect(main_activity).not_to be_valid
    end

    it "prevent children as parents" do
      main_activity.parent = child_activity

      expect(main_activity).not_to be_valid
      expect(main_activity.errors.full_messages).to include "Übergeordnete Aktivität muss ein Haupteintrag sein."
    end

    it "requires absence of technical_requirement for main activity" do
      main_activity.technical_requirement = event_technical_requirements(:wandern)

      expect(main_activity).not_to be_valid
      expect(main_activity.errors.full_messages).to include "Technische Anforderung darf nicht ausgefüllt werden"
    end

    it "does not allow child technical_requirement as technical_requirement" do
      main_activity.technical_requirement = event_technical_requirements(:wandern_t1)

      expect(main_activity).not_to be_valid
      expect(main_activity.errors.full_messages).to include "Technische Anforderung muss eine Hauptanforderung sein"
    end

    it "validates format of color" do
      main_activity.color = "invalid"

      expect(main_activity).not_to be_valid
      expect(main_activity.errors.full_messages).to include(
        "Farbe muss ein zulässiger 6-stelliger Hexadezimal Wert beginnend mit # sein"
      )

      main_activity.color = "#AACCFF"
      expect(main_activity).to be_valid

      main_activity.color = "#aaccff"
      expect(main_activity).to be_valid

      main_activity.color = "#abc"
      expect(main_activity).not_to be_valid
    end

    it "requires absence of color for child activity" do
      child_activity.color = "#aaccff"

      expect(child_activity).not_to be_valid
      expect(child_activity.errors.full_messages).to include "Farbe darf nicht ausgefüllt werden"
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
