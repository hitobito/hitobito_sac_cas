require "spec_helper"

describe TableDisplays::Resolver, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { Person.new(id: 1) }
  let(:parent) { Group.new(id: 1) }

  shared_examples 'resolver' do |attr:, label:, default: nil|
    subject(:resolver) { described_class.new(self, person, attr) }

    it "returns '#{label}' as label for #{attr}" do
      expect(resolver.label).to eq label
    end

    it "returns '#{default}' as default value for #{attr}" do
      expect(resolver.to_s).to eq default
    end
  end

  it_behaves_like 'resolver', attr: :confirmed_at, label: 'E-Mail bestätigt am' do
    it 'returns formatted confirmed_at value' do
      person.confirmed_at = Date.new(2000, 1, 1)
      expect(resolver.to_s).to eq '01.01.2000'
    end
  end

  it_behaves_like 'resolver', attr: :beitragskategorie, label: 'Beitragskategorie' do
    it 'returns Beitragskategorie from role' do
      person.roles.build(group_id: 1, beitragskategorie: :adult)
      expect(resolver.to_s).to eq 'Einzel'
    end

    it 'returns reads from all roles' do
      person.roles.build(group_id: 1, beitragskategorie: :adult)
      person.roles.build(group_id: 1, beitragskategorie: :family)
      expect(resolver.to_s).to eq 'Einzel, Familie'
    end
  end

  it_behaves_like 'resolver', attr: :beitrittsdatum, label: 'Beitritt per' do
    it 'returns convert_on of oldest role within parent group' do
      person.roles.build(group_id: 1, convert_on: Time.zone.local(2024, 1, 11, 10))
      person.roles.build(group_id: 2, convert_on: Time.zone.local(2023, 1, 10, 10))
      person.roles.build(group_id: 1, convert_on: Time.zone.local(2024, 1, 10, 10))

      expect(resolver.to_s).to eq '10.01.2024'
    end
  end

  it_behaves_like 'resolver', attr: :antragsdatum, label: 'Antragsdatum' do
    it 'returns created at of oldest role within parent group' do
      person.roles.build(group_id: 1, created_at: Time.zone.local(2024, 1, 11, 10))
      person.roles.build(group_id: 2, created_at: Time.zone.local(2023, 1, 10, 10))
      person.roles.build(group_id: 1, created_at: Time.zone.local(2024, 1, 10, 10))

      expect(resolver.to_s).to eq '10.01.2024'
    end
  end

  it_behaves_like 'resolver', attr: :antrag_fuer, label: 'Antrag für' do
    { Hauptsektion: [
        Group::SektionsNeuanmeldungenNv::Neuanmeldung,
        Group::SektionsNeuanmeldungenSektion::Neuanmeldung
      ],
      Zusatzsektion: [
        Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
        Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
      ]
    }.each do |expected, role_types|
      role_types.each do |type|
        it "returns #{expected} if has #{type} role in matching group" do
          person.roles.build(group_id: 1, type: type.sti_name)
          expect(resolver.to_s).to eq expected.to_s
        end
        it "is blank if has #{type} role in non matching group" do
          person.roles.build(group_id: 2, type: type.sti_name)
          expect(resolver.to_s).to be_blank
        end
      end
    end
  end

  it_behaves_like 'resolver', attr: :duplicate_exists, label: 'Duplikat', default: 'nein' do
    let(:person) { people(:mitglied) }

    it 'returns nein if duplicate exists but is ignored' do
      PersonDuplicate.create!(person_1: person, person_2: people(:admin), ignore: true)
      expect(resolver.to_s).to eq 'nein'
    end

    it 'returns ja if duplicate exists and is not ignored' do
      PersonDuplicate.create!(person_1: person, person_2: people(:admin), ignore: false)
      expect(resolver.to_s).to eq 'ja'
    end
  end

  it_behaves_like 'resolver', attr: :wiedereintritt, label: 'Wiedereintritt', default: 'nein' do
    let(:person) { people(:mitglied) }

    it 'returns nein if person has active and prior membership' do
      person.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: groups(:matterhorn_mitglieder),
        created_at: 10.days.ago,
        deleted_at: 1.day.ago
      )
      expect(resolver.to_s).to eq 'nein'
    end

    it 'returns ja if person has only prior membership' do
      person.roles.destroy_all
      person.reload.roles.create!(
        type: Group::SektionsMitglieder::Mitglied,
        group: groups(:matterhorn_mitglieder),
        created_at: 10.days.ago,
        deleted_at: 1.day.ago
      )
      expect(resolver.to_s).to eq 'ja'
    end
  end

  it_behaves_like 'resolver', attr: :address_valid, label: 'Adresse gültig', default: 'ja' do
    let(:person) { people(:mitglied) }

    it 'returns ja if person has another tag' do
      person.tags.create!(name: :other)
      expect(resolver.to_s).to eq 'ja'
    end

    it 'returns nein if person has address invalid tag' do
      person.tags.create!(name: PersonTags::Validation::ADDRESS_INVALID)
      expect(resolver.to_s).to eq 'nein'
    end
  end

  it_behaves_like 'resolver', attr: :newsletter, label: 'Newsletter', default: 'nein' do
    let(:person) { people(:mitglied) }

    it 'returns nein if person has another tag' do
      person.tags.create!(name: :other)
      expect(resolver.to_s).to eq 'nein'
    end

    it 'returns ja if person has newsletter tag' do
      person.tags.create!(name: 'newsletter')
      expect(resolver.to_s).to eq 'ja'
    end
  end
end
