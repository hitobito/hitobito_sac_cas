require 'spec_helper'

describe SelfRegistration::Person do
  let(:supplements) { SelfRegistrationNeuanmeldung::Supplements.new({}, groups(:bluemlisalp_mitglieder)) }

  shared_examples :role_building_model do |model_class|
    let(:model) { model_class.new }

    before do
      model.primary_group = groups(:bluemlisalp_neuanmeldungen_sektion)
      model.supplements = supplements
    end

    subject(:role) { model.role }

    it 'builds role with expected type' do
      expect(role).to be_kind_of(Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
    end

    # unsure why we currently do that, see SacCas::SelfRegistration::Person
    describe 'unsure role features in self_registration' do
      it 'sets delete_on' do
        expect(role.delete_on).to be_present
      end

      it 'sets created at before persisting' do
        expect(role).not_to be_persisted
        expect(role.created_at).to be_present
      end
    end

    it 'builds future role if register on is in the future' do
      supplements.register_on = 'jul'
      travel_to(Date.new(2023, 3, 1)) do
        expect(model.supplements).to eq supplements
        expect(role).to be_kind_of(FutureRole)
        expect(role.convert_on).to eq Date.new(2023, 7, 1)
        expect(role.convert_to).to eq Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name
      end
    end

    it 'builds normal role if register on is in the past' do
      supplements.register_on = 'jul'
      travel_to(Date.new(2023, 8, 1)) do
        expect(model.supplements).to eq supplements
        expect(role).to be_kind_of(Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
      end
    end
  end

  it_behaves_like :role_building_model, SelfRegistrationNeuanmeldung::MainPerson
  it_behaves_like :role_building_model, SelfRegistrationNeuanmeldung::Housemate
end
