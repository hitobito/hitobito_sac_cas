# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::MembershipVerifier do

  let(:verifier) { described_class.new(person) }
  let(:person) { Fabricate(:person, birthday: Time.zone.today - 42.years) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  context '#member?' do
    it 'returns true if person has member role' do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
                person: person,
                group: groups(:bluemlisalp_mitglieder),
                created_at: Time.zone.now.beginning_of_year,
                delete_on: Time.zone.today.end_of_year)

      expect(verifier.member?).to eq(true)
    end

    it 'returns false if person has no role' do
      person.roles.destroy_all

      expect(verifier.member?).to eq(false)
    end

    it 'returns false if person has neuanmeldung role' do
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name,
                person: person,
                group: neuanmeldungen_sektion,
                created_at: Time.zone.now.beginning_of_year,
                delete_on: Time.zone.today.end_of_year)

      expect(verifier.member?).to eq(false)
    end
  end
end
