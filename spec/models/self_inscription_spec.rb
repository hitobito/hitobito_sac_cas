# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

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


  ## Would be handy to have those in fixtures ..
  let(:other_group) do
    sektion = Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)

    # TODO - is it expected that I have to create this group by hand?
    Fabricate(Group::SektionsNeuanmeldungenSektion.sti_name, parent: sektion).tap do |g|
      g.update!(self_registration_role_type: registration_role_type)
    end
  end

  it '#attributes= accepts and assigns attributes' do
    model.attributes = { register_on: :now, register_as: :new }

    expect(model.register_as).to eq :new
    expect(model.register_on).to eq :now
  end

  it '#title returns parent group' do
    expect(model.group_for_title).to eq sektion
  end

  it '#save! works for other groups' do
    mitglieder.update!(self_registration_role_type: mitglieder.role_types.first.sti_name)
    build(person: people(:mitglied), group: mitglieder).save!
  end

  describe '#active_member?' do
    it 'is false without active sektion membership' do
      expect(model).not_to be_active_member
    end

    it 'is true with active membership' do
      expect(build(person: mitglied, group: group)).to be_active_member
    end
  end

  describe '#active_in_sektion?' do
    it 'is false without active sektion membership' do
      expect(model).not_to be_active_in_sektion
    end

    it 'is false with active sektion membership in other sektion' do
      expect(build(person: mitglied, group: other_group)).not_to be_active_in_sektion
    end

    it 'is true with active sektion membership in same sektion' do
      expect(build(person: mitglied, group: group)).to be_active_in_sektion
    end
  end

  describe '#register_on_options' do
    subject(:options) { model.register_on_options }

    it 'has 3 items' do
      travel_to(Date.new(2023, 1, 1)) do
        expect(options).to have(3).items
      end
    end

    it 'has key and translation for each item' do
      travel_to(Date.new(2023, 7, 1)) do
        expect(options[0]).to eq(['now', 'Sofort'])
        expect(options[1]).to eq(['jul', '01. Juli'])
        expect(options[2]).to eq(['oct', '01. Oktober'])
      end
    end

    it 'hides july if show after July first' do
      travel_to(Date.new(2023, 7, 2)) do
        expect(options).to have(2).items
        expect(options[0]).to eq(['now', 'Sofort'])
        expect(options[1]).to eq(['oct', '01. Oktober'])
      end
    end

    it 'hides oct if show after October first' do
      travel_to(Date.new(2023, 10, 2)) do
        expect(options).to have(1).items
        expect(options[0]).to eq(['now', 'Sofort'])
      end
    end
  end


  describe '#register_as_options' do
    subject(:options) { model.register_as_options }

    it 'has 1 items' do
      expect(options).to have(1).items
      expect(options[0]).to eq(['replace', 'Neue Stammsektion (ersetzt deine Bisherige)'])
    end

    describe 'with existing membership' do
      let(:person) { roles(:mitglied).person }

      it 'has key and translation for each item' do
        expect(options[0]).to eq(['extra', 'Zusatzsektion'])
        expect(options[1]).to eq(['replace', 'Neue Stammsektion (ersetzt deine Bisherige)'])
      end
    end
  end

  describe 'validations' do
    it 'is valid because of default values' do
      expect(model.register_on).to eq :now
      expect(model.register_as).to eq :replace
    end

    it 'requires register_on to be set' do
      model.register_on = nil
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:register_on)
      expect(model).to have(0).error_on(:register_as)
    end

    describe 'with existing membership' do
      let(:person) { roles(:mitglied).person }

      it 'requires register_at to be set' do
        model.register_as = nil
        expect(model).not_to be_valid
        expect(model).to have(1).error_on(:register_as)
      end
    end
  end

  describe 'save!' do
    let(:neuanmeldungen) { person.roles.where(type: registration_role_type.sti_name) }
    let(:neuanmeldungen_future) { person.roles.where(type: FutureRole.sti_name, convert_to: group.self_registration_role_type) }

    context 'without sektion membership' do
      let(:person) { people(:admin) }

      it 'creates normal role' do
        model.register_on = :now
        expect { model.save! }.to change { neuanmeldungen.count }.by(1)
          .and not_change { neuanmeldungen_future.count }
      end

      it 'creates future role' do
        model.register_on = :jul

        travel_to(Date.new(2023, 5)) do
          expect { model.save! }.to change { neuanmeldungen_future.count }.by(1)
          .and not_change { neuanmeldungen.count }
        end
        expect(neuanmeldungen_future.first.convert_on).to eq Date.new(2023, 7, 1)
      end
    end

    context 'with sektion membership' do
      let(:group) { other_group }

      let(:person) { role.person }
      let(:role) { roles(:mitglied).tap { |r| r.update!(created_at: 2.years.ago) } }

      context 'replacing existing sektion' do
        before { model.register_as = :replace }

        it 'creates normal role and destroys existing membership role' do
          model.register_on = :now
          expect { model.save! }.to change { neuanmeldungen.count }.by(1)
            .and not_change { neuanmeldungen_future.count }
            .and change { role.reload.deleted_at }
        end

        it 'creates future role and marks existing membership role for deletion' do
          model.register_on = :jul
          travel_to(Date.new(2023, 5)) do
            expect { model.save! }.to change { neuanmeldungen_future.count }.by(1)
              .and change { role.reload.delete_on }.from(nil).to(Date.new(2023,7))
              .and not_change { neuanmeldungen.count }
          end
        end
      end

      context 'adding extra sektion' do
        before { model.register_as = :extra }

        it 'creates normal role and destroys existing membership role' do
          model.register_on = :now
          expect { model.save! }.to change { neuanmeldungen.count }.by(1)
            .and not_change { neuanmeldungen_future.count }
          expect { role.reload }.not_to raise_error
        end

        it 'creates future role and marks existing membership role for deletion' do
          model.register_on = :jul
          travel_to(Date.new(2023, 5)) do
            expect { model.save! }.to change { neuanmeldungen_future.count }.by(1)
              .and not_change { role.reload.delete_on }
              .and not_change { neuanmeldungen.count }
          end
        end
      end
    end
  end
end
