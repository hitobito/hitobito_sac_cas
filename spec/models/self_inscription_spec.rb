# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SelfInscription do
  def build(person:, group:)
    described_class.new(person: person, group: group)
  end

  subject(:model) { described_class.new(person: person, group: group) }

  let(:registration_role_type) { Group::SektionsNeuanmeldungenSektion::Neuanmeldung }
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:mitglied) { people(:mitglied) }

  let(:sektion) { groups(:bluemlisalp) }
  let(:person) { Fabricate.build(:person, birthday: 40.years.ago) }
  let(:other_group) { groups(:matterhorn_neuanmeldungen_sektion) }

  it "#title returns parent group" do
    expect(model.group_for_title).to eq sektion
  end

  it "#save! works for other groups" do
    mitglieder.update!(self_registration_role_type: mitglieder.role_types.first.sti_name)
    build(person: people(:mitglied), group: mitglieder).save!
  end

  describe "#active_member?" do
    it "is false without active sektion membership" do
      expect(model).not_to be_active_member
    end

    it "is true with active membership" do
      expect(build(person: mitglied, group: group)).to be_active_member
    end
  end

  describe "#active_in_sektion?" do
    it "is false without active sektion membership" do
      expect(model).not_to be_active_in_sektion
    end

    it "is false with active sektion membership in other sektion" do
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name.to_sym, person: person, group: other_group)
      expect(build(person: person, group: other_group)).not_to be_active_in_sektion
    end

    it "is true with active sektion membership in same sektion" do
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name.to_sym, person: person, group: group)
      expect(build(person: mitglied, group: group)).to be_active_in_sektion
    end
  end

  describe "#register_as_options" do
    subject(:options) { model.register_as_options }

    it "has 1 items" do
      expect(options).to have(1).items
      expect(options[0]).to eq(["replace", "Neue Stammsektion (ersetzt deine Bisherige)"])
    end

    describe "with existing membership" do
      let(:person) { roles(:mitglied).person }

      it "has key and translation for each item" do
        expect(options[0]).to eq(["extra", "Zusatzsektion"])
        expect(options[1]).to eq(["replace", "Neue Stammsektion (ersetzt deine Bisherige)"])
      end
    end
  end

  describe "validations" do
    it "is valid because of default values" do
      expect(model.register_on).to eq "now"
      expect(model.register_as).to eq "replace"
    end

    it "requires register_on to be set" do
      model.register_on = nil
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:register_on)
      expect(model).to have(0).error_on(:register_as)
    end

    describe "with existing membership" do
      let(:person) { roles(:mitglied).person }

      it "requires register_at to be set" do
        model.register_as = nil
        expect(model).not_to be_valid
        expect(model.errors.errors)
          .to include have_attributes(attribute: :register_as, type: :blank)
      end
    end
  end

  describe "save!" do
    let(:neuanmeldungen) { group.class.const_get(:Neuanmeldung).where(person: person) }
    let(:neuanmeldungen_future) { FutureRole.where(person: person, convert_to: group.class.const_get(:Neuanmeldung).sti_name) }
    let(:neuanmeldungen_zusatzsektion) { group.class.const_get(:NeuanmeldungZusatzsektion).where(person: person) }
    let(:neuanmeldungen_zusatzsektion_future) { FutureRole.where(person: person, convert_to: group.class.const_get(:NeuanmeldungZusatzsektion).sti_name) }

    context "without sektion membership" do
      let(:person) { people(:admin) }

      it "creates normal role" do
        model.register_on = :now
        expect { model.save! }.to change { neuanmeldungen.count }.by(1)
          .and not_change { neuanmeldungen_future.count }
          .and not_change { neuanmeldungen_zusatzsektion.count }
          .and not_change { neuanmeldungen_zusatzsektion_future.count }
        expect(model.person.roles.last.delete_on).to be_nil
      end

      it "creates future role" do
        model.register_on = :jul

        travel_to(Date.new(2023, 5)) do
          expect { model.save! }.to change { neuanmeldungen_future.count }.by(1)
            .and not_change { neuanmeldungen.count }
            .and not_change { neuanmeldungen_zusatzsektion.count }
            .and not_change { neuanmeldungen_zusatzsektion_future.count }
        end
        expect(neuanmeldungen_future.first.convert_on).to eq Date.new(2023, 7, 1)
      end
    end

    context "with sektion membership" do
      let(:group) { other_group }
      let(:role) { roles(:mitglied) }
      let(:person) { role.person }

      context "replacing existing sektion" do
        before { model.register_as = :replace }

        it "creates normal role and marks existing membership role as destroyed" do
          model.register_on = :now
          expect { model.save! }.to change { neuanmeldungen.count }.by(1)
            .and not_change { neuanmeldungen_future.count }
            .and not_change { neuanmeldungen_zusatzsektion.count }
            .and not_change { neuanmeldungen_zusatzsektion_future.count }
            .and change { role.reload.deleted_at }.to(Time.zone.yesterday.end_of_day.change(sec: 59))
        end

        it "with fresh membership, creates normal role and marks existing membership role as destroyed" do
          role.update!(created_at: Time.current, delete_on: Date.current.end_of_year)
          model.register_on = :now
          expect { model.save! }.to change { neuanmeldungen.count }.by(1)
            .and not_change { neuanmeldungen_future.count }
            .and not_change { neuanmeldungen_zusatzsektion.count }
            .and not_change { neuanmeldungen_zusatzsektion_future.count }
            .and change { role.reload.deleted_at }.to(Time.zone.yesterday.end_of_day.change(sec: 59))
        end

        it "creates future role and marks existing membership role for deletion" do
          model.register_on = :jul
          travel_to(Date.new(2023, 5)) do
            expect { model.save! }.to change { neuanmeldungen_future.count }.by(1)
              .and change { role.reload.delete_on }.to(Date.new(2023, 6, 30))
              .and not_change { neuanmeldungen.count }
              .and not_change { neuanmeldungen_zusatzsektion.count }
              .and not_change { neuanmeldungen_zusatzsektion_future.count }
          end
        end
      end

      context "adding extra sektion" do
        before do
          # make sure we have a valid primary membership for the whole validity of the new role
          Group::SektionsMitglieder::Mitglied.where(person: person)
            .update_all(delete_on: 1.year.from_now)
          model.register_as = :extra
        end

        it "creates normal zusatzsektion role and does not destroy existing membership role" do
          model.register_on = :now
          expect { model.save! }.to change { neuanmeldungen_zusatzsektion.count }.by(1)
            .and not_change { neuanmeldungen.count }
            .and not_change { neuanmeldungen_future.count }
            .and not_change { neuanmeldungen_zusatzsektion_future.count }
          expect { role.reload }.not_to raise_error
        end

        it "creates future zusatzsektion role and does not mark existing membership role for deletion" do
          model.register_on = :jul
          travel_to(Date.new(2023, 5)) do
            expect { model.save! }.to change { neuanmeldungen_zusatzsektion_future.count }.by(1)
              .and not_change { neuanmeldungen.count }
              .and not_change { neuanmeldungen_zusatzsektion.count }
              .and not_change { neuanmeldungen_future.count }
              .and not_change { role.reload.delete_on }
          end
        end
      end
    end
  end
end
