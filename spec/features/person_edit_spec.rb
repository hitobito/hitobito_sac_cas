# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'person edit page' do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:other) do
    Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)
    .children.find_by(type: Group::SektionsMitglieder)
  end


  describe 'managed' do
    context 'without writing permission on any person' do
      context 'with role with beitragskategorie familie' do
        describe 'her own' do
          before { sign_in(miglied) }

          it 'creates new person as managed and assigns role' do
            visit edit_group_person_path(group_id: geschaeftsstelle.id, id: admin.id)

            find('a[data-association="people_manageds"]').click

            managed_fields = find('#people_manageds_fields')

            managed_fields.fill_in('Vorname', 'Bob')
            managed_fields.fill_in('Nachname', 'Builder')
            managed_fields.fill_in('Geburtsdatum', '11.07.2002')
          end
        end
      end
    end
  end
end
