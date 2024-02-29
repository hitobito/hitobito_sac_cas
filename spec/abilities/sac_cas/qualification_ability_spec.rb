# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe QualificationAbility do

  let(:tourenchef_may_edit_qualification_kind) { Fabricate(:qualification_kind, tourenchef_may_edit: true) }
  let(:tourenchef_may_not_edit_qualification_kind) { Fabricate(:qualification_kind, tourenchef_may_edit: false) }
  let(:bluemlisalp_mitglied) { people(:mitglied) }
  let(:person) { people(:tourenchef) }

  subject(:ability) { Ability.new(person) }

  describe 'as tourenchef' do
    context 'regarding qualification_kind with tourenchef_may_edit true' do
      let(:qualification) { Fabricate(:qualification, qualification_kind: tourenchef_may_edit_qualification_kind) }

      it 'is permitted to create for readable person in layer with tourenchef role' do
        Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
                  person: person,
                  group: groups(:bluemlisalp_funktionaere))
        qualification.person = bluemlisalp_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for non readable person in layer with tourenchef role' do
        qualification.person = bluemlisalp_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for readable person in different layer with tourenchef role' do
        Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
                  person: person,
                  group: groups(:matterhorn_funktionaere))
        qualification.person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                         group: groups(:matterhorn_mitglieder)).person
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for non readable person in different layer with tourenchef role' do
        qualification.person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                         group: groups(:matterhorn_mitglieder)).person
        expect(ability).to_not be_able_to(:create, qualification)
      end
    end

    context 'regarding qualification_kind with tourenchef_may_edit false' do
      let(:qualification) { Fabricate(:qualification, qualification_kind: tourenchef_may_not_edit_qualification_kind) }

      it 'is permitted to create for readable person in layer with tourenchef role' do
        Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
                  person: person,
                  group: groups(:bluemlisalp_funktionaere))
        qualification.person = bluemlisalp_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for non readable person in layer with tourenchef role' do
        qualification.person = bluemlisalp_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for readable person in different layer with tourenchef role' do
        Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
                  person: person,
                  group: groups(:matterhorn_funktionaere))
        qualification.person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                         group: groups(:matterhorn_mitglieder)).person
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it 'is not permitted to create for non readable person in different layer with tourenchef role' do
        qualification.person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                         group: groups(:matterhorn_mitglieder)).person
        expect(ability).to_not be_able_to(:create, qualification)
      end
    end
  end
end
