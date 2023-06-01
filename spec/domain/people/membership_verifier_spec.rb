# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::MembershipVerifier do

  let(:verifier) { described_class.new(person) }
  let(:person) { Fabricate(Group::SektionsMitglieder::Einzel.sti_name.to_sym, group: groups(:be_mitglieder)).person }
  let!(:external_group) { Fabricate(Group::SektionsNeuMitgliederSektion.sti_name.to_sym, name: 'Neuanmeldungen', parent: groups(:be))
 }

  context '#member?' do
    it 'returns true if person has member role' do
      expect(verifier.member?).to eq(true)
    end

    it 'returns true if person has any non external role' do
      Fabricate(Group::SektionsNeuMitgliederSektion::Einzel.name.to_sym,
                group: external_group, person: person)

      expect(verifier.member?).to eq(true)
    end

    it 'returns false if person has no role' do
      person.roles.destroy_all

      expect(verifier.member?).to eq(false)
    end

    it 'returns false if person has only external role' do
      person.roles.destroy_all
      Fabricate(Group::SektionsNeuMitgliederSektion::Einzel.name.to_sym,
                group: external_group, person: person)

      expect(verifier.member?).to eq(false)
    end
  end

  context 'membership_roles' do
    let!(:non_membership_role) { Fabricate(Group::SektionsNeuMitgliederSektion::Einzel.name.to_sym, group: external_group) }
    let!(:person) { non_membership_role.person }
    let!(:membership_roles) do
      [
        Fabricate(Group::SektionsMitglieder::Einzel.sti_name.to_sym,
                  group: groups(:be_mitglieder), person: person),
        Fabricate(Group::SektionsMitglieder::Familie.sti_name.to_sym,
                group: groups(:be_mitglieder), person: person)
      ]
    end

    it 'returns only membership roles' do
      expect(verifier.membership_roles).to match_array(membership_roles)
    end
    
  end

end

