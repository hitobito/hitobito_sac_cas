# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe QualificationAbility do
  let(:tourenchef_may_edit_qualification_kind) { Fabricate(:qualification_kind, tourenchef_may_edit: true) }
  let(:tourenchef_may_not_edit_qualification_kind) { Fabricate(:qualification_kind, tourenchef_may_edit: false) }

  let(:ausserberg_funktionaere) { groups(:bluemlisalp_ortsgruppe_ausserberg_funktionaere) }
  let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }

  let(:ausserberg_mitglied) { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder)).person }
  let(:matterhorn_mitglied) { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
                                        group: groups(:matterhorn_mitglieder)).person }
  let(:ausserberg_tourenchef) { people(:tourenchef) }
  let(:person) { ausserberg_tourenchef }

  subject(:ability) { Ability.new(person) }

  describe 'as tourenchef' do
    context 'regarding qualification_kind with tourenchef_may_edit true' do
      let(:qualification) { Fabricate(:qualification, qualification_kind: tourenchef_may_edit_qualification_kind) }

      context 'for readable person' do
        it 'is permitted to create in same layer as tourenchef role' do
          fabricate_readonly_role(ausserberg_funktionaere)
          qualification.person = ausserberg_mitglied
          expect(ability).to be_able_to(:create, qualification)
        end

        it 'is not permitted to create in different layer than tourenchef role' do
          fabricate_readonly_role(matterhorn_funktionaere)
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        context 'with tourenchef role in layer above' do
          let(:bluemlisalp_tourenkommission) { Fabricate(Group::SektionsTourenkommission.sti_name.to_sym,
                                                         parent: groups(:bluemlisalp)) }
          let(:bluemlisalp_tourenchef) { Fabricate(Group::SektionsTourenkommission::TourenchefSommer.sti_name.to_sym,
                                                   group: bluemlisalp_tourenkommission).person }
          let(:person) { bluemlisalp_tourenchef }

          it 'is not permitted to create' do
            qualification.person = ausserberg_mitglied
            expect(ability).to_not be_able_to(:create, qualification)
          end
        end
      end

      context 'for non readable person' do
        it 'is not permitted to create in same layer as tourenchef role' do
          qualification.person = ausserberg_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        it 'is not permitted to create in different layer than tourenchef role' do
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end
    end

    context 'regarding qualification_kind with tourenchef_may_edit false' do
      let(:qualification) { Fabricate(:qualification, qualification_kind: tourenchef_may_not_edit_qualification_kind) }

      context 'for readable person' do
        it 'is not permitted to create in same layer as tourenchef role' do
          fabricate_readonly_role(ausserberg_funktionaere)
          qualification.person = ausserberg_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        it 'is not permitted to create in different layer than tourenchef role' do
          fabricate_readonly_role(matterhorn_funktionaere)
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end

      context 'for non readable person' do
        it 'is not permitted to create in same layer as tourenchef role' do
          qualification.person = ausserberg_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end


        it 'is not permitted to create in different layer than tourenchef role' do
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end
    end
  end

  def fabricate_readonly_role(group)
    Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
              person: ausserberg_tourenchef,
              group: group)
  end
end
