# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Export::Tabular::People::SacMitgliedRow do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }
  subject(:row) { described_class.new(person.reload, group) }

  # Fixture roles are valid during 2015, so setup current time accordingly
  before { travel_to '2015-07-01' }

  it '#adresszusatz returns nil for now' do
    expect(row.adresszusatz).to be_nil
  end

  it '#anzahl_die_alpen returns 0' do
    expect(row.anzahl_die_alpen).to eq(0)
  end

  it '#anzahl_sektionsbulletin returns 0' do
    expect(row.anzahl_sektionsbulletin).to eq(0)
  end

  describe '#begünstigt' do
    before do
      expect(person.roles).not_to include an_instance_of(Group::SektionsMitglieder::Beguenstigt)
    end

    context 'without beguenstigt role' do
      it 'returns "No"' do
        expect(row.begünstigt).to eq('No')
      end
    end

    context 'with beguenstigt role in a sibling layer' do
      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
                  group: groups(:matterhorn_mitglieder), person: person)
        expect(row.begünstigt).to eq('No')
      end
    end

    context 'with beguenstigt role in ancestor layer' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
                  group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.begünstigt).to eq('No')
      end
    end


    context 'with beguenstigt role in a descendent layer' do
      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
                  group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
        Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
                  group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
        expect(row.begünstigt).to eq('No')
      end
    end

    context 'with beguenstigt role in the same layer' do
      it 'returns "Yes"' do
        Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
                  group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.begünstigt).to eq('Yes')
      end
    end
  end

  describe '#beitragskategorie' do
    let(:person) { Fabricate(:person) }

    context 'without mitglied role' do
      it 'returns nil' do
        expect(row.beitragskategorie).to be_nil
      end
    end

    context 'with neuanmeldung role in same layer' do
      it 'returns nil' do
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
                  group: groups(:bluemlisalp_neuanmeldungen_nv), person: person)
        expect(row.beitragskategorie).to be_nil
      end
    end

    context 'with mitglied role in sibling layer' do
      it 'returns nil' do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                  group: groups(:matterhorn_mitglieder), person: person)
        expect(row.beitragskategorie).to be_nil
      end
    end

    context 'with mitglied role in ancestor layer' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

      it 'returns nil' do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                  group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.beitragskategorie).to be_nil
      end
    end

    context 'with mitglied role in descendent layer' do
      it 'returns nil' do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                  group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
        expect(row.beitragskategorie).to be_nil
      end
    end

    context 'with mitglied role in same layer' do
      it 'returns role#beitragskategorie' do
        role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                         group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.beitragskategorie).to eq('EINZEL')
      end
    end

    context 'with mitglied_zusatzsektion role in same layer' do
      it 'returns role#beitragskategorie' do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                  group: groups(:matterhorn_mitglieder), person: person)
        role = Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
                         group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.beitragskategorie).to eq('EINZEL')
      end
    end
  end

  it '#bemerkungen returns person#additional_information' do
    person.update(additional_information: 'Some additional information')
    expect(row.bemerkungen).to eq('Some additional information')
  end

  it '#birthday returns person#birthday in dd.mm.yyyy format' do
    person.update(birthday: Date.new(1234, 5, 6))
    expect(row.birthday).to eq('06.05.1234')
  end

  describe '#country' do
    it 'returns country code for non-CH country' do
      person.update(country: 'DE')
      expect(row.country).to eq('DE')
    end

    it 'returns nil for CH country' do
      person.update(country: 'CH')
      expect(row.country).to be_nil
    end
  end

  describe '#ehrenmitglied' do
    before do
      expect(person.roles).not_to include an_instance_of(Group::SektionsMitglieder::Ehrenmitglied)
    end

    context 'without ehrenmitglied role' do
      it 'returns "No"' do
        expect(row.ehrenmitglied).to eq('No')
      end
    end

    context 'with ehrenmitglied role in a sibling layer' do
      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
                  group: groups(:matterhorn_mitglieder), person: person)
        expect(row.ehrenmitglied).to eq('No')
      end
    end

    context 'with ehrenmitglied role in ancestor layer' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
                  group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.ehrenmitglied).to eq('No')
      end
    end

    context 'with ehrenmitglied role in descendent layer' do
      it 'returns "No"' do
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
                  group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
        Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
                  group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)
        expect(row.ehrenmitglied).to eq('No')
      end
    end

    context 'with ehrenmitglied role in the same layer' do
      it 'returns "Yes"' do
        Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
                  group: groups(:bluemlisalp_mitglieder), person: person)
        expect(row.ehrenmitglied).to eq('Yes')
      end
    end
  end

  it '#eintrittsjahr returns year of first role creation' do
    expect(person.roles).to be_present
    # person has currently valid roles, lets create an older deleted one
    first_role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                           group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
                           person: person,
                           created_at: 5.years.ago,
                           deleted_at: 4.years.ago)

    expect(row.eintrittsjahr).to eq(first_role.created_at.year)
  end

  describe '#gender' do
    it 'returns "Weiblich" for "w"' do
      person.update!(gender: 'w')
      expect(row.gender).to eq('Weiblich')
    end

    it 'returns "Männlich" for "m"' do
      person.update!(gender: 'm')
      expect(row.gender).to eq('Männlich')
    end

    it 'returns "Andere" for nil' do
      person.update!(gender: nil)
      expect(row.gender).to eq('Andere')
    end
  end

  describe '#language' do
    it 'returns "D" for "de"' do
      person.update!(language: 'de')
      expect(row.language).to eq('D')
    end

    it 'returns "F" for "fr"' do
      person.update!(language: 'fr')
      expect(row.language).to eq('F')
    end

    it 'returns "ITS" for "it"' do
      person.update!(language: 'it')
      expect(row.language).to eq('ITS')
    end

    it 'returns language code in uppercase for unknown language' do
      person.update_column(:language, 'englisch')
      expect(row.language).to eq('ENGLISCH')
    end
  end

  it '#layer_navision_id returns group#navision_id_padded' do
    expect(row.layer_navision_id_padded).to eq(group.navision_id_padded)
  end

  it '#phone_number returns any number for given label' do
    mobile1 = Fabricate(:phone_number, contactable: person, label: 'mobile', number: '0781234567')
    mobile2 = Fabricate(:phone_number, contactable: person, label: 'mobile', number: '0782345678')
    expect(row.phone_number('mobile')).to eq(mobile1.number).or eq(mobile2.number)
  end

  it '#phone_number_mobile returns any number with label mobile' do
    mobile = Fabricate(:phone_number, contactable: person, label: 'mobile', number: '0781234567')
    expect(row.phone_number_mobile).to eq mobile.number
  end

  it '#postfach returns nil for now' do
    expect(row.postfach).to be_nil
  end

  it '#s_info_1 returns nil for now' do
    expect(row.s_info_1).to be_nil
  end

  it '#s_info_2 returns nil for now' do
    expect(row.s_info_2).to be_nil
  end

  it '#s_info_3 returns nil for now' do
    expect(row.s_info_3).to be_nil
  end

  it '#saldo returns nil for now' do
    expect(row.saldo).to be_nil
  end

  it '#empty returns nil' do
    expect(row.empty).to be_nil
  end
end
