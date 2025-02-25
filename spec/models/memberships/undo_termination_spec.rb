# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::UndoTermination, versioning: true do
  before { PaperTrail.request.controller_info = {mutation_id: Random.uuid} }

  def with_mutation_id(mutation_id = Random.uuid)
    PaperTrail.request(controller_info: {mutation_id: mutation_id}) { yield }
  end

  def update_terminated!(role, value)
    # monkey dance required because directly assigning terminated intentionally raises error
    role = roles(role) if role.is_a?(Symbol)
    role.tap { _1.write_attribute(:terminated, value) }.save!
  end

  let(:role) { roles(:mitglied) }

  subject { described_class.new(role) }

  describe "#initialize" do
    it "raises an ArgumentError if called without a membership role" do
      expect { described_class.new(nil) }
        .to raise_error(ArgumentError, "Must be called with a membership role")

      expect { described_class.new(roles(:abonnent_alpen)) }
        .to raise_error(ArgumentError, "Must be called with a membership role")
    end

    it "does not raise an ArgumentError if called with a Mitglied role" do
      expect { described_class.new(roles(:mitglied)) }.not_to raise_error
    end

    it "does not raise an ArgumentError if called with a MitgliedZusatzsektion role" do
      expect { described_class.new(roles(:mitglied_zweitsektion)) }.not_to raise_error
    end
  end

  describe "#mutation_id" do
    it "returns the mutation_id from version" do
      update_terminated!(role, true)
      expect(subject.mutation_id).to eq(role.versions.last.mutation_id)
    end

    it "returns the mutation_id from version where terminated flag changed to true" do
      with_mutation_id("expected mutation id") do
        update_terminated!(role, true)
      end

      with_mutation_id("not the one where terminated flag was set") do
        role.update!(start_on: 10.years.ago)
      end

      expect(subject.mutation_id).to eq("expected mutation id")
    end

    it "returns the mutation_id of the latest termination" do
      with_mutation_id("earlier termination") { update_terminated!(role, true) }
      with_mutation_id("role restored") { update_terminated!(role, false) }
      with_mutation_id("latest termination") { update_terminated!(role, true) }

      expect(subject.mutation_id).to eq("latest termination")
    end

    it "returns nil if no version has terminated flag changed to true" do
      PaperTrail::Version.delete_all
      role.update!(end_on: 10.years.from_now)

      expect(subject.mutation_id).to be_nil
    end
  end

  describe "#role_versions" do
    it "returns all versions of roles with matching mutation_id" do
      with_mutation_id("relevant mutations") do
        update_terminated!(role, true) # mark role as terminated

        # update roles and random other model instances with  the same mutation_id
        roles(:familienmitglied_kind, :abonnent_alpen).each do |r|
          r.update!(end_on: 10.years.from_now)
        end
        mailing_lists(:newsletter).update!(name: "PeakUpdates")
        events(:top_course).update!(number: "123abc")
        people(:tourenchef).update!(language: "fr")
      end

      # update another role with an unrelated mutation_id
      with_mutation_id("unrelated mutations") do
        roles(:familienmitglied).update!(end_on: 10.years.from_now)
      end

      # make sure our setup is correct and mutation_id returns the expected value
      expect(subject.mutation_id).to eq("relevant mutations")

      expect(subject.role_versions).to all have_attributes(mutation_id: "relevant mutations")
      expect(subject.role_versions.map(&:item)).to match_array [
        role, roles(:familienmitglied_kind), roles(:abonnent_alpen)
      ]
    end

    it "returns an empty array if mutation_id is nil" do
      with_mutation_id(nil) do # versions get created with blank mutation_id
        update_terminated!(role, true)
        update_terminated!(:familienmitglied_kind, true)
      end

      expect(subject.role_versions).to be_empty
    end
  end

  describe "#restored_roles" do
    it "returns the roles with their original values" do
      update_terminated!(role, true)

      changed_role = roles(:familienmitglied_kind)
      original_attributes = changed_role.attributes
      changed_role.update!(
        start_on: 10.years.ago,
        end_on: 10.years.from_now,
        label: "new label",
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder)
      )

      # make sure our setup is correct
      expect(subject.mutation_id).to eq(role.versions.last.mutation_id)
      expect(subject.restored_roles).to match_array [role, changed_role]

      restored_role = subject.restored_roles.find { _1 == changed_role }

      # paper_trail #reify is used behind-the-scenes and it clears the `updated_at` timestamp,
      # so we must ignore it here
      expect(restored_role.attributes.except("updated_at"))
        .to eq original_attributes.except("updated_at")
    end
  end

  describe "#restored_people" do
    let(:role) { roles(:familienmitglied) }

    it "returns people with current attrs but original household_key" do
      original_household_key = role.person.household_key

      mitglied_original_language = role.person.language
      update_terminated!(role, true)
      role.person.update!(household_key: "familie_new_key", language: "fr")

      kind_original_birthday = roles(:familienmitglied_kind).person.birthday
      update_terminated!(:familienmitglied_kind, true)
      roles(:familienmitglied_kind).person.update!(
        household_key: "familie_new_key",
        birthday: 100.years.ago
      )

      expect(subject.restored_people)
        .to match_array [role.person, roles(:familienmitglied_kind).person]

      mitglied = subject.restored_people.find { _1 == role.person }
      expect(mitglied.household_key).to eq original_household_key
      expect(mitglied.language).not_to eq mitglied_original_language

      kind = subject.restored_people.find { _1 == roles(:familienmitglied_kind).person }
      expect(kind.household_key).to eq original_household_key
      expect(kind.birthday).not_to eq kind_original_birthday
    end
  end

  context "validations" do
    before { update_terminated!(role, true) }

    # make sure our setup is valid
    it "is valid" do
      update_terminated!(role, true)
      expect(subject).to be_valid
    end

    describe "#mutation_id" do
      it "is valid if mutation_id is present" do
        allow(subject).to receive(:mutation_id).and_return("some mutation id")
        expect(subject).to be_valid
      end

      it "is invalid if mutation_id is blank" do
        allow(subject).to receive(:mutation_id).and_return(nil)
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["Mutation kann nicht gefunden werden"]
      end
    end

    describe "#validate_role_is_terminated" do
      it "is valid if role is terminated" do
        expect(role).to be_terminated
        expect(subject).to be_valid
      end

      it "is invalid if role is not terminated" do
        update_terminated!(role, false)
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include "Rolle ist nicht gekündigt"
      end
    end

    describe "#validate_roles_unchanged" do
      it "is valid if roles are unchanged since termination" do
        expect(role.versions).to have(1).item
        expect(role.versions.last.changeset).to eq("terminated" => [false, true])

        expect(subject).to be_valid
      end

      it "is invalid if roles are changed since termination" do
        role.update!(end_on: 10.years.from_now)
        expect(role.versions).to have(2).items

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to eq ["SAC Blüemlisalp → Mitglieder: Mitglied (Stammsektion) (Einzel) von Edmund Hillary wurde seit der Kündigung verändert"]
      end
    end

    describe "#validate_restored_roles" do
      # modify the terminated role by yesterday (use update_column as not to trigger papertrail).
      # the restored role will have the original validity again.
      before { role.update_column(:end_on, Date.yesterday) }

      it "is valid if restored roles are valid" do
        # the role will still be valid with the original validity
        expect(subject).to be_valid
      end

      it "is invalid if restored roles are invalid" do
        # we create a Neuanmeldung role for the person valid from today. This causes the restored
        # role with the original validity to be invalid as it overlaps with the Neuanmeldung role.
        new_role = Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(
          person: role.person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
          start_on: Date.current
        )

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to eq ["SAC Blüemlisalp → Mitglieder: Mitglied (Stammsektion) (Einzel) von Edmund Hillary: Person hat bereits eine Neuanmeldung (von #{I18n.l(new_role.start_on)} bis )."]
      end
    end

    describe "#validate_household_keys_compatible" do
      let(:role) { roles(:familienmitglied) }

      it "is valid if current household keys are blank" do
        expect do
          role.person.update!(household_key: nil)
          update_terminated!(role, true)
        end.to change { role.person.reload.household_key }.to(nil)

        expect(subject).to be_valid
      end

      it "is valid if current household keys are same as restored" do
        expect do
          update_terminated!(role, true)
        end.not_to change { role.person.reload.household_key }

        expect(subject).to be_valid
      end

      it "is invalid if current household keys are different from restored" do
        expect do
          role.person.update!(household_key: "new_key")
          update_terminated!(role, true)
        end.to change { role.person.reload.household_key }.to("new_key")

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to eq ["Tenzing Norgay wurde seit der Kündigung einer anderen Familie zugeordnet"]
      end
    end
  end

  describe "#save!" do
    it "raises an error if not valid" do
      allow(subject).to receive(:valid?).and_return(false)

      expect { subject.save! }.to raise_error.with_message(/Validation failed:/)
    end

    it "saves #restored_roles and #restored_people without validations" do
      new_person = Person.new
      new_role = Group::SektionsNeuanmeldungenNv::Neuanmeldung.new(
        person: people(:abonnent),
        group_id: 42,
        beitragskategorie: "dummy"
      )

      allow(subject).to receive(:valid?).and_return(true)
      allow(subject).to receive(:restored_roles).and_return([new_role])
      allow(subject).to receive(:restored_people).and_return([new_person])

      expect { subject.save! }
        .to change { Person.count }.by(1)
        .and change { Group::SektionsNeuanmeldungenNv::Neuanmeldung.count }.by(1)

      expect(new_person).to be_persisted
      expect(new_role).to be_persisted
    end
  end
end
