# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::Neuanmeldungen::Promoter do
  def create_neuanmeldung_role(family_main_person: true, **opts)
    person = Fabricate(:person, sac_family_main_person: family_main_person)
    Fabricate(
      :role,
      person: person,
      **opts.reverse_merge(
        type: Group::SektionsNeuanmeldungenNv::Neuanmeldung.name.to_sym,
        group: groups(:bluemlisalp_neuanmeldungen_nv),
        created_at: Time.current.beginning_of_year
      )
    )
  end

  context "#promote" do
    it "does nothing when promotable? is false" do
      neuanmeldung_role = instance_double("Group::SektionsMitglieder::Neuanmeldung")
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(false)

      expect { subject.promote(neuanmeldung_role) }
        .to(not_change { Role.count })
    end

    it "creates a new role when promotable? is true" do
      neuanmeldung_role = create_neuanmeldung_role

      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect { subject.promote(neuanmeldung_role) }
        .to change { Group::SektionsNeuanmeldungenNv::Neuanmeldung.count }.by(-1)
        .and change { Group::SektionsMitglieder::Mitglied.count }.by(1)

      expect { neuanmeldung_role.reload }.to raise_error(ActiveRecord::RecordNotFound)

      mitglied_role = neuanmeldung_role.person.roles.last
      expect(mitglied_role).to be_a(Group::SektionsMitglieder::Mitglied)
    end

    it "sets beitragskategorie from Neuanmeldung" do
      SacCas::Beitragskategorie::Calculator::BEITRAGSKATEGORIEN.each do |beitragskategorie|
        neuanmeldung_role = create_neuanmeldung_role(beitragskategorie: beitragskategorie)
        expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

        expect { subject.promote(neuanmeldung_role) }
          .to change { Group::SektionsMitglieder::Mitglied.count }.by(1)

        expect(neuanmeldung_role.person.roles.last.beitragskategorie).to eq(beitragskategorie)
      end
    end

    it "sets timestamps" do
      freeze_time
      neuanmeldung_role = create_neuanmeldung_role
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect { subject.promote(neuanmeldung_role) }
        .to change { Group::SektionsMitglieder::Mitglied.count }.by(1)

      mitglied_role = neuanmeldung_role.person.roles.last
      expect(mitglied_role.created_at).to eq(Time.current)
      expect(mitglied_role.delete_on).to eq(Date.current.end_of_year)
    end

    it "creates a new Mitglied role when a Neuanmeldung is promoted" do
      neuanmeldung_role = create_neuanmeldung_role(
        type: Group::SektionsNeuanmeldungenNv::Neuanmeldung.name
      )
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect { subject.promote(neuanmeldung_role) }
        .to change { Group::SektionsMitglieder::Mitglied.count }.by(1)

      mitglied_role = neuanmeldung_role.person.roles.last
      expect(mitglied_role).to be_a(Group::SektionsMitglieder::Mitglied)
    end

    it "creates a new MitgliedZusatzsektion role when a NeuanmeldungZusatzsektion is promoted" do
      # For the new MitgliedZusatzektion role to be valid, we need a Mitglied role valid during the
      # whole active_period of the new MitgliedZusatzsektion role, but in a different section.
      mitglied_role = Fabricate(
        Group::SektionsMitglieder::Mitglied.name.to_sym,
        group: groups(:matterhorn_mitglieder),
        created_at: Time.current,
        delete_on: Date.current.end_of_year
      )
      neuanmeldung_role = create_neuanmeldung_role(
        type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.name,
        person: mitglied_role.person
      )
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect { subject.promote(neuanmeldung_role) }
        .to change { Group::SektionsMitglieder::MitgliedZusatzsektion.count }.by(1)

      zusatzsektion_role = neuanmeldung_role.person.roles.last
      expect(zusatzsektion_role).to be_a(Group::SektionsMitglieder::MitgliedZusatzsektion)
    end

    it "logs error when validation fails" do
      # Let's try to create a MitgliedZusatzsektion role for a person that is not a Mitglied.
      # This should fail with a validation error.
      neuanmeldung_role = create_neuanmeldung_role(
        type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.name
      )
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect { subject.promote(neuanmeldung_role) }
        .to not_change { Role.count }
        .and change { HitobitoLogEntry.count }.by(1)

      expect(HitobitoLogEntry.last).to have_attributes(
        message: match(/Gültigkeitsprüfung ist fehlgeschlagen: Person muss Mitglied sein während /),
        level: "error",
        subject: neuanmeldung_role.person,
        category: "neuanmeldungen",
        payload: {
          role: {id: neuanmeldung_role.id, type: neuanmeldung_role.class.sti_name},
          person: {id: neuanmeldung_role.person.id, name: neuanmeldung_role.person.full_name},
          group: {id: neuanmeldung_role.group.id, path: "SAC/CAS/SAC Blüemlisalp/Neuanmeldungen"}
        }.deep_stringify_keys
      )
    end

    it "logs error when an error occurs" do
      neuanmeldung_role = create_neuanmeldung_role
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true)

      expect(neuanmeldung_role).to receive(:destroy!)
        .and_raise("Oh my gosh, something ugly happened!")

      expect { subject.promote(neuanmeldung_role) }
        .to not_change { Role.count }
        .and change { HitobitoLogEntry.count }.by(1)

      expect(HitobitoLogEntry.last).to have_attributes(
        message: "Oh my gosh, something ugly happened!",
        level: "error",
        subject: neuanmeldung_role.person,
        category: "neuanmeldungen",
        payload: {
          role: {id: neuanmeldung_role.id, type: neuanmeldung_role.class.sti_name},
          person: {id: neuanmeldung_role.person.id, name: neuanmeldung_role.person.full_name},
          group: {id: neuanmeldung_role.group.id, path: "SAC/CAS/SAC Blüemlisalp/Neuanmeldungen"}
        }.deep_stringify_keys
      )
    end

    it "does not log duplicate errors" do
      neuanmeldung_role = create_neuanmeldung_role
      expect(subject).to receive(:promotable?).with(neuanmeldung_role).and_return(true).twice

      expect(neuanmeldung_role).to receive(:destroy!)
        .and_raise("Oh my gosh, something ugly happened!").twice

      expect { subject.promote(neuanmeldung_role) }
        .to change { HitobitoLogEntry.count }.by(1)

      expect { subject.promote(neuanmeldung_role) }
        .to not_change { HitobitoLogEntry.count }
    end
  end

  context "#promoteable?" do
    it "is true when all conditions are satisfied" do
      People::Neuanmeldungen::Promoter::CONDITIONS.each do |condition|
        expect(condition).to receive(:satisfied?).and_return(true)
      end

      expect(subject.promotable?(double)).to eq true
    end

    People::Neuanmeldungen::Promoter::CONDITIONS.each do |condition|
      it "is false when condition #{condition.name} is not satisfied" do
        (People::Neuanmeldungen::Promoter::CONDITIONS - [condition]).each do |other_condition|
          allow(other_condition).to receive(:satisfied?).and_return(true)
        end
        expect(condition).to receive(:satisfied?).and_return(false)

        expect(subject.promotable?(double)).to eq false
      end
    end
  end

  context "#candidate_roles" do
    it "returns all Neuanmeldung and NeuanmeldungZusatzsektion roles" do
      expect(Group::SektionsNeuanmeldungenNv::Neuanmeldung).not_to exist
      expect(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion).not_to exist

      neuanmeldung1 = create_neuanmeldung_role
      neuanmeldung2 = create_neuanmeldung_role(group: groups(:matterhorn_neuanmeldungen_nv))
      neuanmeldung_zusatzsektion = create_neuanmeldung_role(
        type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.name
      )

      expect(subject.candidate_roles).to match_array(
        [
          neuanmeldung1,
          neuanmeldung2,
          neuanmeldung_zusatzsektion
        ]
      )
    end
  end

  context "#call" do
    it "calls promote for each element of candidate_roles" do
      candidates = [double("candidate1"), double("candidate2"), double("candidate3")]
      expect(subject).to receive(:candidate_roles).and_return(candidates)
      expect(candidates).to receive(:find_each)
        .and_yield(candidates[0])
        .and_yield(candidates[1])
        .and_yield(candidates[2])

      expect(subject).to receive(:promote).with(candidates[0])
      expect(subject).to receive(:promote).with(candidates[1])
      expect(subject).to receive(:promote).with(candidates[2])

      subject.call
    end

    it "continues with next candidate when an error occurs" do
      candidates = Fabricate.build_times(
        3,
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
        group: groups(:bluemlisalp_neuanmeldungen_nv)
      )

      expect(subject).to receive(:candidate_roles).and_return(candidates)
      expect(candidates).to receive(:find_each)
        .and_yield(candidates[0])
        .and_yield(candidates[1])
        .and_yield(candidates[2])

      expect(subject).to receive(:promotable?).and_return(true).exactly(3).times

      candidates.each do |candidate|
        expect(candidate).to receive(:destroy!).and_raise
      end

      expect(subject).to receive(:promote).with(candidates[0]).and_call_original
      expect(subject).to receive(:promote).with(candidates[1]).and_call_original
      expect(subject).to receive(:promote).with(candidates[2]).and_call_original

      subject.call
    end
  end
end
