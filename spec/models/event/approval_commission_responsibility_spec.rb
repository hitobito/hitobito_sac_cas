# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApprovalCommissionResponsibility do
  subject(:event_approval_commission_responsibility) {
    event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder_subito)
  }

  describe "validations" do
    it "is valid" do
      expect(subject).to be_valid
    end

    it "sektion is readonly" do
      subject.update!(sektion: groups(:matterhorn),
        freigabe_komitee: Group::FreigabeKomitee.create!(name: "FreigabeKomitee Matterhorn",
          parent: groups(:matterhorn_touren_und_kurse)))
      subject.reload
      expect(subject.sektion).to eq groups(:bluemlisalp)
    end

    it "target_group is readonly" do
      subject.update!(target_group: nil)
      subject.reload
      expect(subject.target_group).to eq event_target_groups(:kinder)
    end

    it "discipline is readonly" do
      subject.update!(discipline: nil)
      subject.reload
      expect(subject.discipline).to eq event_disciplines(:wandern)
    end

    it "subito is readonly" do
      subject.update!(subito: nil)
      subject.reload
      expect(subject.subito).to be_truthy
    end

    it "validates uniqness of sektion_id in scope" do
      clone = described_class.new(subject.attributes.slice(*%w[sektion_id target_group_id discipline_id
        freigabe_komitee_id subito]))
      expect(clone).not_to be_valid
      expect(clone.errors.full_messages).to eq ["Sektion hat bereits eine entsprechende Zuständigkeit definiert."]
    end

    it "validates presence of freigabe_komitee" do
      subject.freigabe_komitee = nil
      expect(subject).not_to be_valid
    end

    it "validates that freigabe_komitee must be in layer" do
      subject.freigabe_komitee = Group::FreigabeKomitee.create!(name: "FreigabeKomitee Matterhorn",
        parent: groups(:matterhorn_touren_und_kurse))
      expect(subject).not_to be_valid
      expect(event_approval_commission_responsibility.errors.full_messages).to include "Freigabekomitee ist nicht " \
      "in der gleichen Sektion/Ortsgruppe."
    end

    it "validates that target_group is a parent" do
      event_approval_commission_responsibility = described_class.new(target_group: event_target_groups(:senioren_a))
      expect(event_approval_commission_responsibility).not_to be_valid
      expect(event_approval_commission_responsibility.errors
                                                     .full_messages).to include "Zielgruppe ist keine Hauptzielgruppe."
    end

    it "validates that discipline is a parent" do
      event_approval_commission_responsibility = described_class.new(discipline: event_disciplines(:eisklettern))
      expect(event_approval_commission_responsibility).not_to be_valid
      expect(event_approval_commission_responsibility.errors
                                                     .full_messages).to include "Disziplin ist keine Hauptdisziplin."
    end
  end
end
