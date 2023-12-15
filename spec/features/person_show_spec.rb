# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'person show page' do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:other) do
    Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)
    .children.find_by(type: Group::SektionsMitglieder)
  end


  describe 'roles' do
    describe 'her own' do
      before { sign_in(admin) }

      it 'shows link to change main group' do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link 'Hauptgruppe setzen'
      end

      it 'shows link to change main group if person is Mitglied in a Sektion' do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: admin, beitragskategorie: :einzel)
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link 'Hauptgruppe setzen'
        expect(page).to have_css('section.roles', text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion) (Bis 31.12.2023) (Einzel)")
      end
    end

    describe 'others' do
      before { sign_in(admin) }

      it 'shows Hauptgruppe setzen link to ' do
        visit group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
        expect(page).to have_link 'Hauptgruppe setzen'
      end
    end
  end
end
