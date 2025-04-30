# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::UndoTermination, versioning: true do
  before { PaperTrail.request.controller_info = {mutation_id: Random.uuid} }

  def mutation(mutation_id = Random.uuid)
    PaperTrail.request(controller_info: {mutation_id: mutation_id}) { yield }
  end

  def terminate(role, terminate_on: Date.current.yesterday)
    role = roles(role) if role.is_a?(Symbol)
    termination = Memberships::TerminateSacMembership.new(
      role, terminate_on, termination_reason_id: termination_reasons(:deceased).id
    )
    expect(termination).to be_valid
    termination.save!
    role.reload
  end

  let(:person) { Fabricate(:person) }
  let(:role) {
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
      person: person, group: groups(:bluemlisalp_mitglieder), start_on: 1.year.ago)
  }

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
    let(:role) { roles(:mitglied) }

    it "returns the mutation_id from version" do
      terminate(role)

      expect(subject.mutation_id).to eq(role.versions.last.mutation_id)
    end

    it "returns the mutation_id from version where terminated flag changed to true" do
      mutation("expected mutation id") do
        terminate(role)
      end

      mutation("not the one where terminated flag was set") do
        role.update!(start_on: 10.years.ago)
      end

      expect(subject.mutation_id).to eq("expected mutation id")
    end

    it "returns the mutation_id of the latest termination" do
      mutation("earlier termination") { terminate(role, terminate_on: Date.current.end_of_year) }
      mutation("role restored") { described_class.new(role).save! }
      mutation("latest termination") { terminate(role.reload) }

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
      mutation("relevant mutations") do
        terminate(role)

        # update roles and random other model instances with  the same mutation_id
        roles(:familienmitglied_kind, :abonnent_alpen).each do |r|
          r.update!(end_on: 10.years.from_now)
        end
        people(:tourenchef).update!(language: "fr")
      end

      # update another role with an unrelated mutation_id
      mutation("unrelated mutations") do
        roles(:familienmitglied).update!(end_on: 10.years.from_now)
      end

      # make sure our setup is correct and mutation_id returns the expected value
      expect(subject.mutation_id).to eq("relevant mutations")

      expect(subject.role_versions).to all have_attributes(mutation_id: "relevant mutations")
      expect(subject.role_versions.map(&:reify)).to match_array [
        role, roles(:familienmitglied_kind), roles(:abonnent_alpen)
      ]
    end

    it "returns an empty array if mutation_id is nil" do
      mutation(nil) do # versions get created with blank mutation_id
        terminate(role)
        terminate(:familienmitglied)
      end

      expect(subject.role_versions).to be_empty
    end

    it "returns the first version with matching mutation_id when multiple exist" do
      mutation("multiple versions with same mutation id") do
        expect(role.versions).to have(1).item
        role.update!(end_on: 10.years.from_now)
        expect(role.versions).to have(2).item
        expected_version = role.versions.last

        role.update!(end_on: 20.years.from_now)
        terminate(role)
        expect(role.versions).to have(4).items

        expect(subject.role_versions).to eq [expected_version]
      end
    end
  end

  describe "#restored_roles" do
    it "returns the roles with their original values" do
      terminate(role)

      changed_role = roles(:familienmitglied_kind)
      original_attributes = changed_role.attributes
      changed_role.update!(
        start_on: 10.years.ago,
        end_on: 5.days.ago,
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

    it "returns the role with its original values when role was updated multiple times in the same mutation" do
      mutation("multiple versions with same mutation id") do
        expect(role.versions).to have(1).item
        original_start_on = role.start_on
        role.update!(start_on: original_start_on - 10.years)
        terminate(role)
        role.update!(start_on: original_start_on - 5.years)
        expect(role.versions).to have(4).items

        expect(subject.restored_roles).to match_array [role]
        expect(subject.restored_roles.first.start_on).to eq original_start_on
      end
    end

    it "returns the role with its original end_to if it was shorted in a later mutation" do
      original_end_on = role.end_on

      mutation { terminate(role, terminate_on: 1.day.ago) }
      mutation { role.update!(end_on: 1.week.ago) } # <- shorted after termination

      expect(subject.restored_roles).to match_array [role]
      restored_role = subject.restored_roles.find { _1 == role }
      expect(restored_role.end_on).to eq original_end_on
    end

    it "returns the role with the current end_on if it was extended in a later mutation" do
      extended_end_on = 10.years.from_now.to_date

      mutation { terminate(role, terminate_on: 1.day.ago) }
      mutation { role.update!(end_on: extended_end_on) } # <- extended after termination

      expect(subject.restored_roles).to match_array [role]
      expect(subject.restored_roles.first.end_on).to eq extended_end_on
    end
  end

  describe "#restored_people" do
    let(:role) { roles(:familienmitglied) }

    it "returns people with current attrs but original household_key" do
      original_household_key = role.person.household_key
      mitglied_original_language = role.person.language
      kind_original_birthday = roles(:familienmitglied_kind).person.birthday

      terminate(role) # terminates all family members roles

      role.person.update!(household_key: "familie_new_key", language: "fr")
      roles(:familienmitglied_kind).person.update!(
        household_key: "familie_new_key",
        birthday: 100.years.ago
      )

      expect(subject.restored_people)
        .to include role.person, roles(:familienmitglied_kind).person

      mitglied = subject.restored_people.find { _1 == role.person }
      expect(mitglied.household_key).to eq original_household_key
      expect(mitglied.language).not_to eq mitglied_original_language

      kind = subject.restored_people.find { _1 == roles(:familienmitglied_kind).person }
      expect(kind.household_key).to eq original_household_key
      expect(kind.birthday).not_to eq kind_original_birthday
    end

    it "reassigns the original sac_family_main_person" do
      expect(role.person).to be_sac_family_main_person
      terminate(role)
      expect(role.person).not_to be_sac_family_main_person

      restored_person = subject.restored_people.find { |p| p.id == role.person.id }
      expect(restored_person).to be_sac_family_main_person
    end
  end

  context "validations" do
    # make sure our setup is valid
    it "is valid" do
      terminate(role)
      expect(subject).to be_valid
    end

    describe "#mutation_id" do
      before { terminate(role) }

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
        terminate(role)
        expect(subject).to be_valid
      end

      it "is invalid if role is not terminated" do
        expect(role).not_to be_terminated

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include "Rolle ist nicht gekündigt"
      end
    end

    describe "#validate_roles_unchanged" do
      it "is valid if roles are unchanged since termination" do
        mutation do
          role.update!(start_on: role.start_on - 1.day)
        end

        mutation do
          terminate(role) # <- termination is the latest mutation
        end

        expect(role.versions).to have(3).items
        expect(role.versions.last.changeset).to eq(
          "terminated" => [false, true],
          "termination_reason_id" => [nil, termination_reasons(:deceased).id],
          "end_on" => [Date.current.end_of_year, Date.current.yesterday]
        )

        expect(subject).to be_valid
      end

      it "is invalid if roles are changed since termination" do
        mutation do
          terminate(role)
        end

        mutation do
          role.update!(start_on: role.start_on - 1.day) # <- mutation after termination
        end

        expect(role.versions).to have(3).items
        expect(role.versions.last.changeset.keys).not_to include("terminated")
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to eq ["SAC Blüemlisalp → Mitglieder: Mitglied (Stammsektion) (Einzel) von #{role.person} wurde seit der Kündigung verändert"]
      end
    end

    describe "#validate_restored_roles" do
      before { terminate(role) }

      it "is valid if restored roles are valid" do
        # the role will still be valid with the original validity
        expect(subject).to be_valid
      end

      it "is invalid if restored roles are invalid" do
        role.update_column(:end_on, 1.day.ago)

        # we create a Neuanmeldung role for the person valid from today. This causes the restored
        # role with the original validity to be invalid as it overlaps with the Neuanmeldung role.
        new_role = Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(
          person: role.person,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
          start_on: Date.current
        )

        expect(subject).not_to be_valid
        expect(subject.errors.full_messages)
          .to eq ["SAC Blüemlisalp → Mitglieder: Mitglied (Stammsektion) (Einzel) von #{role.person}: Person hat bereits eine Neuanmeldung (von #{I18n.l(new_role.start_on)} bis )."]
      end
    end

    describe "#validate_household_keys_compatible" do
      let(:role) { roles(:familienmitglied) }

      it "is valid if current household keys are blank" do
        expect do
          # instant termination clears the household
          terminate(role)
        end.to change { role.person.reload.household_key }.to(nil)
        expect(subject).to be_valid
      end

      it "is valid if current household keys are same as restored" do
        expect do
          # future termination keeps the household intact
          terminate(role, terminate_on: Date.current.end_of_year)
        end.not_to change { role.person.reload.household_key }

        expect(subject).to be_valid
      end

      it "is invalid if current household keys are different from restored" do
        expect { terminate(role) }.to change { role.person.reload.household_key }.to(nil)

        # simulate that the person has joined another family in the meantime
        mutation { role.person.update!(household_key: "new-family") }

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

    context "for family membership" do
      let(:role) { roles(:familienmitglied) }

      it "saves restored family" do
        original_household_key = role.person.household_key
        original_household_people = role.person.household.people

        terminate(role)
        expect(role).to be_terminated
        expect(role.person.household_key).to eq(nil)

        subject.save!

        expect(role.reload).not_to be_terminated
        expect(role.person.household_key).to eq original_household_key
        expect(role.person.household.people).to match_array original_household_people
      end
    end
  end
end
