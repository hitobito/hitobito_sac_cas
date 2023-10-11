# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::MembershipVerifier do

  let(:verifier) { described_class.new(person) }
  let(:person) { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:be_mitglieder)).person }
  let!(:neuanmeldungen) { Fabricate(Group::SektionsNeuanmeldungenSektion.sti_name.to_sym, name: 'Neuanmeldungen', parent: groups(:be))
 }

  context '#member?' do
    it 'returns true if person has member role' do
      expect(verifier.member?).to eq(true)
    end

    it 'returns true if person has one active member role' do
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name.to_sym,
                group: neuanmeldungen, person: person)

      expect(verifier.member?).to eq(true)
    end

    it 'returns false if person has no role' do
      person.roles.destroy_all

      expect(verifier.member?).to eq(false)
    end

    it 'returns false if person has no active member role' do
      person.roles.destroy_all
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name.to_sym,
                group: neuanmeldungen, person: person)

      expect(verifier.member?).to eq(false)
    end
  end
end

