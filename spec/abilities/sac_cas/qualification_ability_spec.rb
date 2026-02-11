# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe QualificationAbility do
  let(:tourenchef_may_edit_qualification_kind) do
    Fabricate(:qualification_kind, tourenchef_may_edit: true)
  end
  let(:tourenchef_may_not_edit_qualification_kind) do
    Fabricate(:qualification_kind, tourenchef_may_edit: false)
  end

  let(:ausserberg_funktionaere) { groups(:bluemlisalp_ortsgruppe_ausserberg_funktionaere) }
  let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }

  let(:ausserberg_mitglied) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder)).person
  end
  let(:matterhorn_mitglied) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      group: groups(:matterhorn_mitglieder)).person
  end
  let(:ausserberg_tourenchef) { people(:tourenchef) }
  let(:person) { ausserberg_tourenchef }
  let(:bluemlisalp_mitglied) { people(:mitglied) }

  subject(:ability) { Ability.new(person) }

  def fabricate_readonly_role(group)
    Fabricate(Group::SektionsFunktionaere::AdministrationReadOnly.sti_name.to_sym,
      person: ausserberg_tourenchef,
      group: group)
  end

  describe "as tourenchef" do
    context "regarding qualification_kind with tourenchef_may_edit true" do
      let(:qualification) do
        Fabricate(:qualification, qualification_kind: tourenchef_may_edit_qualification_kind)
      end

      context "for readable person" do
        it "is permitted to create in same layer as tourenchef role" do
          fabricate_readonly_role(ausserberg_funktionaere)
          qualification.person = ausserberg_mitglied
          expect(ability).to be_able_to(:create, qualification)
        end

        it "is not permitted to create in different layer than tourenchef role" do
          fabricate_readonly_role(matterhorn_funktionaere)
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        context "with writing permission on Mitglieder" do
          let!(:writing_permission) do
            Group::SektionsMitglieder::Schreibrecht.create(person: person,
              group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))
          end

          it "is permitted to create for member" do
            qualification.person = ausserberg_mitglied
            expect(ability).to be_able_to(:create, qualification)
          end
        end

        context "with tourenchef role in layer above" do
          let(:bluemlisalp_sektionsfunktionaere) do
            Group::SektionsFunktionaere.find_by(parent: groups(:bluemlisalp))
          end
          let(:bluemlisalp_touren_und_kurse) do
            Group::SektionsTourenUndKurse
              .find_or_create_by(parent: bluemlisalp_sektionsfunktionaere)
          end
          let(:bluemlisalp_tourenchef) do
            Fabricate(Group::SektionsTourenUndKurse::TourenchefSommer.sti_name.to_sym,
              group: bluemlisalp_touren_und_kurse).person
          end
          let(:person) { bluemlisalp_tourenchef }

          it "is not permitted to create" do
            qualification.person = ausserberg_mitglied
            expect(ability).to_not be_able_to(:create, qualification)
          end
        end
      end

      context "for non readable person" do
        it "is not permitted to create in different layer than tourenchef role" do
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end
    end

    context "regarding qualification_kind with tourenchef_may_edit false" do
      let(:qualification) do
        Fabricate(:qualification, qualification_kind: tourenchef_may_not_edit_qualification_kind)
      end

      context "for readable person" do
        it "is not permitted to create in same layer as tourenchef role" do
          fabricate_readonly_role(ausserberg_funktionaere)
          qualification.person = ausserberg_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        it "is not permitted to create in different layer than tourenchef role" do
          fabricate_readonly_role(matterhorn_funktionaere)
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end

        it "is not permitted to create for member in same layer as tourenchef role" do
          qualification.person = ausserberg_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end

      context "for non readable person" do
        it "is not permitted to create in different layer than tourenchef role" do
          qualification.person = matterhorn_mitglied
          expect(ability).to_not be_able_to(:create, qualification)
        end
      end
    end
  end

  describe "with layer_and_below_full" do
    let(:qualification_kind) { qualification_kinds(:ski_leader) }
    let(:qualification) do
      Fabricate(:qualification,
        qualification_kind: qualification_kind,
        person: bluemlisalp_mitglied)
    end

    context "layer_and_below_full in top layer" do
      let(:person) { people(:admin) }

      it "is permitted to create and destroy" do
        expect(ability).to be_able_to(:create, qualification)
        expect(ability).to be_able_to(:destroy, qualification)
      end

      it "is permitted to create and destroy even with Mitgliederverwaltungs role" do
        expect(ability).to be_able_to(:create, qualification)
        expect(ability).to be_able_to(:destroy, qualification)
      end
    end

    describe Group::SektionsFunktionaere::Administration do
      let(:person) { create_funktionaer(Group::SektionsFunktionaere::Administration).person.reload }

      it "is not permitted to create and destroy" do
        expect(ability).to_not be_able_to(:create, qualification)
        expect(ability).to_not be_able_to(:destroy, qualification)
      end
    end

    describe Group::SektionsFunktionaere::Mitgliederverwaltung do
      let(:person) do
        create_funktionaer(Group::SektionsFunktionaere::Mitgliederverwaltung).person.reload
      end

      it "is not permitted to create and destroy" do
        expect(ability).not_to be_able_to(:create, qualification)
        expect(ability).not_to be_able_to(:destroy, qualification)
      end

      it "is permitted if has another role with layer_and_below_full" do
        Fabricate(Group::Geschaeftsstelle::Admin.sti_name, group: groups(:geschaeftsstelle),
          person: person)

        expect(ability).to be_able_to(:create, qualification)
        expect(ability).to be_able_to(:destroy, qualification)
      end
    end
  end

  describe "as sektionsfunktionaere administrator" do
    let(:person) { create_funktionaer(Group::SektionsFunktionaere::Administration).person.reload }

    context "regarding qualification_kind with tourenchef_may_edit true" do
      let(:qualification) do
        Fabricate(:qualification, qualification_kind: tourenchef_may_edit_qualification_kind,
          person: bluemlisalp_mitglied)
      end

      it "is permitted to create in same layer as administrator role" do
        expect(ability).to be_able_to(:create, qualification)
      end

      it "is not permitted to create in different layer than administrator role" do
        fabricate_readonly_role(matterhorn_funktionaere)
        qualification.person = matterhorn_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end
    end

    context "regarding qualification_kind with tourenchef_may_edit false" do
      let(:qualification) do
        Fabricate(:qualification,
          qualification_kind: tourenchef_may_not_edit_qualification_kind,
          person: bluemlisalp_mitglied)
      end

      it "is not permitted to create in same layer as administrator role" do
        expect(ability).to_not be_able_to(:create, qualification)
      end

      it "is not permitted to create in different layer than administrator role" do
        fabricate_readonly_role(matterhorn_funktionaere)
        qualification.person = matterhorn_mitglied
        expect(ability).to_not be_able_to(:create, qualification)
      end
    end
  end

  def create_funktionaer(role)
    Fabricate(role.sti_name, group: groups(:bluemlisalp_funktionaere))
  end
end
