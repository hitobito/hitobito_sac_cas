# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Groups::Primary do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

  def identify(person)
    described_class.new(person).identify
  end

  it 'has expected ROLE_TYPES' do
    expect(described_class::ROLE_TYPES).to eq [
      Group::SektionsMitglieder::Mitglied.sti_name,
      Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name
    ]
  end

  it 'is nil when no roles exists' do
    expect(identify(Person.new)).to eq nil
  end

  it 'is first group for person with single role' do
    expect(identify(admin)).to eq geschaeftsstelle
    expect(identify(mitglied)).to eq mitglieder
  end

  it 'favours older over newer' do
    travel_to 1.day.from_now do
      Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: admin)
    end
    expect(identify(admin)).to eq geschaeftsstelle
    travel_to 1.day.ago do
      Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: admin)
    end
    expect(identify(admin)).to eq funktionaere
  end

  it 'favours preferred_role over other'  do
    travel_to 1.day.from_now do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: admin, beitragskategorie: :einzel)
    end
    expect(identify(admin)).to eq mitglieder

    travel_to 1.day.ago do
      Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: admin)
    end
    expect(identify(admin)).to eq mitglieder
  end

  describe 'two preferred_roles' do
    let!(:other) do
      Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023).children
        .find_by(type: Group::SektionsMitglieder)
    end

    it 'favours older over newer' do
      travel_to 1.day.from_now do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other, person: admin, beitragskategorie: :einzel)
      end
      expect(identify(mitglied)).to eq mitglieder

      travel_to 1.day.ago do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other, person: mitglied, beitragskategorie: :einzel)
      end
      expect(identify(mitglied)).to eq other
    end
  end
end
