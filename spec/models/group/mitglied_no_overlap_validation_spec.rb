# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe :mitglied_no_overlap_validation do
  context "no overlapping primary memberships" do
    shared_examples "allows only one active role at a time" do |mitglied_type|
      context "for #{mitglied_type.sti_name}" do
        let(:existing_role) do
          Fabricate(
            mitglied_type.sti_name,
            group: group,
            start_on: Time.zone.parse("2019-01-01"),
            end_on: Time.zone.parse("2019-12-31")
          )
        end

        it "allows disjoint active_period" do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: existing_role.group,
            start_on: existing_role.end_on + 1.day,
            end_on: existing_role.end_on + 2.days
          )

          expect(new_role).to be_valid

          new_role.end_on = existing_role.start_on - 1.day
          new_role.created_at = existing_role.created_at - 2.days

          expect(new_role).to be_valid
        end

        it "denies concurrent active_period for same type in same layer" do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: existing_role.group,
            created_at: existing_role.created_at,
            end_on: existing_role.end_on
          )

          expect(new_role).not_to be_valid
          expect(new_role.errors[:person]).to eq [error_message]
        end

        it "denies concurrent active_period in different sektion" do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: other_sektion_group,
            created_at: existing_role.created_at,
            end_on: existing_role.end_on
          )

          expect(new_role).not_to be_valid
          expect(new_role.errors[:person]).to eq [error_message]
        end

        it "denies concurrent active_period for other mitglied types" do
          other_mitglied_types_map.each do |other_type, other_type_group|
            new_role = Fabricate.build(
              other_type.sti_name,
              person: existing_role.person,
              group: other_type_group,
              created_at: existing_role.created_at,
              end_on: existing_role.end_on
            )

            expect(new_role).not_to be_valid, "expected #{other_type.sti_name} to be invalid"
            expect(new_role.errors[:person]).to eq [error_message]
          end
        end
      end
    end

    it_behaves_like "allows only one active role at a time", Group::SektionsMitglieder::Mitglied do
      let(:error_message) { "ist bereits Mitglied (von 01.01.2019 bis 31.12.2019)." }
      let(:group) { groups(:bluemlisalp_mitglieder) }
      let(:other_sektion_group) { groups(:matterhorn_mitglieder) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsNeuanmeldungenSektion::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_sektion),
          Group::SektionsNeuanmeldungenNv::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_nv)
        }
      end
    end

    it_behaves_like "allows only one active role at a time", Group::SektionsNeuanmeldungenSektion::Neuanmeldung do
      let(:error_message) { "hat bereits eine Neuanmeldung (von 01.01.2019 bis 31.12.2019)." }
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
      let(:other_sektion_group) { groups(:matterhorn_neuanmeldungen_sektion) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsMitglieder::Mitglied => groups(:bluemlisalp_mitglieder),
          Group::SektionsNeuanmeldungenNv::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_nv)
        }
      end
    end

    it_behaves_like "allows only one active role at a time", Group::SektionsNeuanmeldungenNv::Neuanmeldung do
      let(:error_message) { "hat bereits eine Neuanmeldung (von 01.01.2019 bis 31.12.2019)." }
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
      let(:other_sektion_group) { groups(:matterhorn_neuanmeldungen_nv) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsMitglieder::Mitglied => groups(:bluemlisalp_mitglieder),
          Group::SektionsNeuanmeldungenSektion::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_sektion)
        }
      end
    end
  end

  context "no overlapping memberships per layer" do
    let(:person) { Fabricate(:person) }

    def build_role(type, group_fixture_name)
      Fabricate.build(
        type.sti_name,
        person: person,
        group: groups(group_fixture_name),
        beitragskategorie: "adult",
        start_on: Time.zone.parse("2019-01-01"),
        end_on: Time.zone.parse("2019-12-31")
      )
    end

    def expect_overlap_error(role)
      role.validate
      expect(role.errors.errors)
        .to include(have_attributes(attribute: :person, type: :already_has_neuanmeldung_role))
        .or(include(have_attributes(attribute: :person, type: :already_has_mitglied_role)))
    end

    def expect_no_overlap_error(role)
      role.validate
      expect(role.errors.errors)
        .not_to include(
          have_attributes(attribute: :person, type: :already_has_neuanmeldung_role),
          have_attributes(attribute: :person, type: :already_has_mitglied_role)
        )
    end

    shared_examples "deny concurrent role in same layer" do |existing:, new:|
      context "for #{existing.first.sti_name} and #{new.first.sti_name}" do
        let(:existing_role) { build_role(*existing).tap { |r| r.save(validate: false) } }
        let(:new_role) { build_role(*new) }

        it "allows disjoint active_period" do
          new_role.attributes = {
            created_at: existing_role.end_on + 1.day,
            end_on: existing_role.end_on + 2.days
          }
          expect_no_overlap_error(new_role)

          new_role.attributes = {
            created_at: existing_role.created_at - 2.days,
            end_on: existing_role.created_at - 1.day
          }

          expect_no_overlap_error(new_role)
        end

        it "denies concurrent active_period" do
          new_role.attributes = {
            created_at: existing_role.created_at,
            end_on: existing_role.end_on
          }

          expect_overlap_error(new_role)
        end
      end
    end

    shared_examples "allow concurrent role in lower layer" do |existing:, new:|
      context "for #{existing.first.sti_name} and #{new.first.sti_name}" do
        let(:existing_role) { build_role(*existing).tap { |r| r.save(validate: false) } }
        let(:new_role) { build_role(*new) }

        it "allows concurrent active_period" do
          new_role.attributes = {
            created_at: existing_role.created_at,
            end_on: existing_role.end_on
          }

          expect_no_overlap_error(new_role)
        end
      end
    end

    shared_examples "deny concurrent role in lower layer" do |existing:, new:|
      context "for #{existing.first.sti_name} and #{new.first.sti_name}" do
        let(:existing_role) { build_role(*existing).tap { |r| r.save(validate: false) } }
        let(:new_role) { build_role(*new) }

        it "denies concurrent active_period" do
          new_role.attributes = {
            created_at: existing_role.created_at,
            end_on: existing_role.end_on
          }

          expect_overlap_error(new_role)
        end
      end
    end

    # Stammsektion Mitgliedschaften/Neuanmeldungen
    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      new: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder]

    it_behaves_like "deny concurrent role in lower layer",
      existing: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      new: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder]

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      new: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion]

    it_behaves_like "deny concurrent role in lower layer",
      existing: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      new: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv]

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      new: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder]

    it_behaves_like "deny concurrent role in lower layer",
      existing: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      new: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder]

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      new: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion]

    it_behaves_like "deny concurrent role in lower layer",
      existing: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      new: [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv]

    # Zusatzsektion Mitgliedschaften/Neuanmeldungen

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder],
      new: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder]

    it_behaves_like "allow concurrent role in lower layer",
      existing: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder],
      new: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_mitglieder]

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder],
      new: [Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion, :bluemlisalp_neuanmeldungen_sektion]

    it_behaves_like "allow concurrent role in lower layer",
      existing: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder],
      new: [Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv]

    # Stammsektion + Zusatzsektion

    it_behaves_like "deny concurrent role in same layer",
      existing: [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      new: [Group::SektionsMitglieder::MitgliedZusatzsektion, :bluemlisalp_mitglieder]
  end
end
