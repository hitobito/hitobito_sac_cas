# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Discipline do
  let(:main_discipline) { event_disciplines(:wandern) }
  let(:child_discipline) { event_disciplines(:wanderweg) }

  it ".list orders entries" do
    expect(main_discipline.children.list)
      .to eq(event_disciplines(:wanderweg, :bergtour, :schneeschuh))
  end

  it ".main only returns parents" do
    expect(described_class.main)
      .to match_array(event_disciplines(:wandern, :hochtour, :klettern))
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
      entry = Fabricate.build(:event_discipline, parent: child_discipline)
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
      main_discipline.children.update_all(deleted_at: Time.zone.now)
      main_discipline.update(deleted_at: Time.zone.now)
    end

    it "contains no soft deleted entries" do
      expect(described_class.assignable.count).to eq(described_class.without_deleted.count)
      expect(described_class.assignable).not_to include(child_discipline)
    end

    it "contains entries for passed ids even if they are not soft deleted" do
      discipline = event_disciplines(:felsklettern)
      expect(described_class.assignable(discipline.id)).to include(discipline)
      expect(described_class.assignable.count).to eq(described_class.without_deleted.count)
    end

    it "contains entries for passed ids even if they are soft deleted" do
      expect(described_class.assignable(child_discipline.id)).to include(child_discipline)
      expect(described_class.assignable(main_discipline.children.pluck(:id)).count).to eq(described_class.count)
      expect(described_class.assignable(main_discipline.id)).to include(main_discipline)
    end

    it "contains parents for passed ids even if they are soft deleted" do
      expect(described_class.assignable(child_discipline.id)).to include(main_discipline)
    end
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { event_disciplines(:indoorklettern).destroy }
        .to change { described_class.unscoped.count }.by(-1)
        .and change { Event::Discipline::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      expect { child_discipline.destroy }
        .to change { described_class.unscoped.count }.by(0)
        .and change { Event::Discipline::Translation.count }.by(0)
      expect(child_discipline.deleted_at).to be_present
      expect(child_discipline.translations).to be_present
    end

    it "prevents delete if children exist" do
      expect { main_discipline.destroy }.not_to change { described_class.unscoped.count }
      expect(main_discipline.errors.details[:base]).to eq [error: :has_children]
      expect(main_discipline.deleted_at).to be_nil
    end

    it "soft deletes if children are all deleted" do
      event_disciplines(:skihochtour).update!(deleted_at: Time.zone.now)
      event_disciplines(:snowboardhochtour).update!(deleted_at: Time.zone.now)
      expect { event_disciplines(:hochtour).destroy }
        .not_to change { described_class.unscoped.count }
      expect(event_disciplines(:hochtour).deleted_at).to be_present
    end

    it "deletes event_approval_commission_responsiblities on destroy" do
      event_disciplines(:klettern).children.destroy_all
      expect { event_disciplines(:klettern).destroy }.to change { Event::ApprovalCommissionResponsibility.count }
    end

    it "does not delete event_approval_commission_responsiblities on soft destroy" do
      expect { event_disciplines(:klettern).destroy }.not_to change { Event::ApprovalCommissionResponsibility.count }
    end
  end
end
