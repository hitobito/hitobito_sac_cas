#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RolesController do
  before { sign_in(people(:admin)) }

  let(:person) { Fabricate(:person) }

  describe "DELETE destroy" do
    context "for neuanmeldungs role" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

      it "destroys household" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.set_family_main_person!
        role = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: group, beitragskategorie: :family, person: person)

        other = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder)).person
        other2 = Fabricate(:person, birthday: 12.years.ago)

        household.add(other)
        household.add(other2)
        household.save!

        expect(household.people).to match_array([person, other, other2])

        delete :destroy, params: {group_id: group.id, id: role.id}

        household = person.reload.household

        expect(household.people).to match_array([person])
      end
    end

    context "for abo role" do
      let(:group) { groups(:abo_die_alpen) }

      it "does not destroy household" do
        household = Household.new(person, maintain_sac_family: false, validate_members: false)
        household.set_family_main_person!
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: groups(:bluemlisalp_neuanmeldungen_nv), beitragskategorie: :family, person: person)
        role = Fabricate(Group::AboMagazin::Andere.sti_name.to_sym, group: group)

        other = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:matterhorn_mitglieder)).person
        other2 = Fabricate(:person, birthday: 12.years.ago)

        household.add(other)
        household.add(other2)
        household.save!

        expect(household.people).to match_array([person, other, other2])

        delete :destroy, params: {group_id: group.id, id: role.id}

        household = person.reload.household

        expect(household.people).to match_array([person, other, other2])
      end
    end
  end
end
