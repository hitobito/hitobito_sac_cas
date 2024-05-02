# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe SacSectionMembershipConfigAbility do

  let(:config) { sac_section_membership_configs(:'2024') }
  let(:admin) { people(:admin) }
  let(:mitgliederverwaltung_sektion) do
    Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
              group: groups(:bluemlisalp_funktionaere)).person
  end
  let(:mitglied) { people(:mitglied) }

  context 'manage' do
    it 'is permitted as admin' do
      expect(Ability.new(admin)).to be_able_to(:manage, config)
    end

    it 'is permitted as mitgliederverwaltung sektion' do
      expect(Ability.new(mitgliederverwaltung_sektion)).to be_able_to(:manage, config)
    end

    it 'is permitted as mitgliederverwaltung sektion on ortsgruppe' do
      ortsgruppen_config = config.dup
      ortsgruppen_config.group = groups(:bluemlisalp_ortsgruppe_ausserberg)
      ortsgruppen_config.save!

      expect(Ability.new(mitgliederverwaltung_sektion)).to be_able_to(:manage, ortsgruppen_config)
    end

    it 'is not permitted for mitglied' do
      expect(Ability.new(mitglied)).not_to be_able_to(:manage, config)
    end

    it 'is not permitted for mitgliederverwaltung sektion for other sektion' do
      other_sac_section_config = config.dup
      other_sac_section_config.group = groups(:matterhorn)
      other_sac_section_config.save!

      expect(Ability.new(mitgliederverwaltung_sektion)).not_to be_able_to(:manage, other_sac_section_config)
    end
  end
end
