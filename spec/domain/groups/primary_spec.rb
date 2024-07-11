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

  it "has expected ROLE_TYPES" do
    expect(described_class::ROLE_TYPES).to eq [
      Group::SektionsMitglieder::Mitglied.sti_name,
      Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name
    ]
  end

  it "is nil when no roles exists" do
    expect(identify(Person.new)).to eq nil
  end

  it "is first group for person with single role" do
    expect(identify(admin)).to eq geschaeftsstelle
    expect(identify(mitglied)).to eq mitglieder
  end

  it "favours older over newer" do
    # person has geschaeftsstelle role with created_at=now from fixtures
    Fabricate(
      Group::SektionsFunktionaere::Praesidium.sti_name,
      group: funktionaere,
      person: admin,
      created_at: 1.day.from_now # younger role
    )
    expect(identify(admin)).to eq geschaeftsstelle

    Fabricate(
      Group::SektionsFunktionaere::Praesidium.sti_name,
      group: funktionaere,
      person: admin,
      created_at: 1.day.ago # older role
    )
    expect(identify(admin)).to eq funktionaere
  end

  it "favours preferred_role over other" do
    Fabricate(
      Group::SektionsMitglieder::Mitglied.sti_name,
      group: mitglieder,
      person: admin,
      beitragskategorie: :adult
    )
    expect(identify(admin)).to eq mitglieder

    Fabricate(
      Group::SektionsFunktionaere::Praesidium.sti_name,
      group: funktionaere,
      person: admin,
      created_at: 1.day.ago # older role, but not preferred
    )
    expect(identify(admin)).to eq mitglieder
  end
end
