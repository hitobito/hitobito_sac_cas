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

  describe "updating freigabe_komitee" do
    let(:touren_und_kurse) { groups(:bluemlisalp_touren_und_kurse) }
    let(:bluemlisalp) { groups(:bluemlisalp) }
    let(:freigabe_komitee_a) do
      Fabricate(Group::FreigabeKomitee.sti_name.to_sym, parent: touren_und_kurse, layer_group_id: bluemlisalp.id)
    end
    let(:freigabe_komitee_b) do
      Fabricate(Group::FreigabeKomitee.sti_name.to_sym, parent: touren_und_kurse, layer_group_id: bluemlisalp.id)
    end
    let(:klettern) { event_disciplines(:klettern) }
    let(:hochtour) { event_disciplines(:hochtour) }
    let(:familien) { event_target_groups(:familien) }
    let(:senioren) { event_target_groups(:senioren) }

    subject do
      assign_approval_commission_responsibility(discipline: hochtour, target_group: senioren,
        freigabe_komitee: freigabe_komitee_b)
    end

    it "removes approvals by old and new freigabe_komitee on tours where discipline and target_group are matching" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: senioren,
        freigabe_komitee: freigabe_komitee_a)

      tour = create_tour

      to_delete_a = create_approval(tour, freigabe_komitee_a)
      to_delete_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to change { Event::Approval.count }.by(-2)

      expect(Event::Approval.where(id: [to_delete_a, to_delete_b].map(&:id))).to be_empty
    end

    it "removes approvals by old and new freigabe_komitee on tours where sub discipline is matching" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: senioren,
        freigabe_komitee: freigabe_komitee_a)

      disciplines = Event::Discipline.where(parent: [hochtour, klettern])
      tour = create_tour(disciplines:)

      to_delete_a = create_approval(tour, freigabe_komitee_a)
      to_delete_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to change { Event::Approval.count }.by(-2)

      expect(Event::Approval.where(id: [to_delete_a, to_delete_b].map(&:id))).to be_empty
    end

    it "removes approvals by old and new freigabe_komitee on tours where sub target group is matching" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: senioren,
        freigabe_komitee: freigabe_komitee_a)

      target_groups = Event::TargetGroup.where(parent: [familien, senioren])
      tour = create_tour(target_groups:)

      to_delete_a = create_approval(tour, freigabe_komitee_a)
      to_delete_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to change { Event::Approval.count }.by(-2)

      expect(Event::Approval.where(id: [to_delete_a, to_delete_b].map(&:id))).to be_empty
    end

    it "keeps approvals by old and new freigabe_komitee on tours with approval in progress states" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: senioren,
        freigabe_komitee: freigabe_komitee_a)

      tour = create_tour(state: :draft)

      to_keep_a = create_approval(tour, freigabe_komitee_a)
      to_keep_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to_not change { Event::Approval.count }

      tour.update!(state: :review)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_b)
      end.to_not change { Event::Approval.count }

      expect(Event::Approval.where(id: [to_keep_a, to_keep_b].map(&:id))).to be_present
    end

    it "keeps approvals by old and new freigabe_komitee on tours in different sektion" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: senioren,
        freigabe_komitee: freigabe_komitee_a)

      tour = create_tour(groups: [groups(:matterhorn)], state: :approved)

      to_keep_a = create_approval(tour, freigabe_komitee_a)
      to_keep_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to_not change { Event::Approval.count }

      expect(Event::Approval.where(id: [to_keep_a, to_keep_b].map(&:id))).to be_present
    end

    it "keeps approvals by old and new freigabe_komitee on tours where discipline and target_group are not matching" do
      assign_approval_commission_responsibility(discipline: klettern, target_group: familien,
        freigabe_komitee: freigabe_komitee_a)

      disciplines = [klettern]
      target_groups = [familien]
      tour = create_tour(disciplines:, target_groups:)

      to_keep_a = create_approval(tour, freigabe_komitee_a)
      to_keep_b = create_approval(tour, freigabe_komitee_b)

      expect do
        subject.update!(freigabe_komitee: freigabe_komitee_a)
      end.to_not change { Event::Approval.count }

      expect(Event::Approval.where(id: [to_keep_a, to_keep_b].map(&:id))).to be_present
    end
  end

  def assign_approval_commission_responsibility(discipline:, target_group:, freigabe_komitee:)
    Event::ApprovalCommissionResponsibility.find_by(sektion: bluemlisalp, discipline:,
      target_group:, subito: false).tap do |responsibility|
      responsibility.update!(freigabe_komitee:)
    end
  end

  def create_approval(tour, freigabe_komitee)
    Event::Approval.create!(freigabe_komitee: freigabe_komitee,
      event: tour,
      approval_kind: event_approval_kinds(:professional),
      creator: people(:admin))
  end

  def create_tour(**attrs)
    Fabricate(:sac_tour, attrs.reverse_merge(
      disciplines: [hochtour, klettern],
      target_groups: [familien, senioren],
      technical_requirements: [event_technical_requirements(:klettern)],
      fitness_requirement: event_fitness_requirements(:a),
      season: :winter,
      state: :approved,
      description: "Schöne Tour"
    ))
  end
end
