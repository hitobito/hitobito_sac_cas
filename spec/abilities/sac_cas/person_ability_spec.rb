# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe PersonAbility do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:funktionaere) { groups(:bluemlisalp_funktionaere) }

  subject(:ability) { Ability.new(person.reload) }

  describe "primary_group" do
    context "mitglied updating himself" do
      let(:person) { people(:mitglied) }

      it "is permitted" do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end

    context "admin updating mitglied" do
      let(:person) { admin }

      it "is permitted" do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end
  end

  describe "create_households" do
    [Group::Geschaeftsstelle::Mitarbeiter, Group::Geschaeftsstelle::Admin].each do |role_type|
      context role_type do
        let(:person) { Fabricate(role_type.sti_name, group: groups(:geschaeftsstelle)).person }

        it "is permitted" do
          expect(ability).to be_able_to(:create_households, mitglied)
        end
      end
    end

    [Group::SektionsFunktionaere::Mitgliederverwaltung,
      Group::SektionsFunktionaere::Administration].each do |role_type|
      context role_type do
        let(:person) {
          Fabricate(role_type.sti_name, group: groups(:bluemlisalp_funktionaere)).person
        }

        it "is not permitted" do
          expect(ability).not_to be_able_to(:create_households, mitglied)
        end
      end
    end
  end

  describe "sac_remarks" do
    let(:person) { people(:admin) }

    context "as member" do
      before { person.roles.destroy_all }

      it "is not permitted to manage remarks" do
        expect(ability).not_to be_able_to(:show_remarks, person)
        expect(ability).not_to be_able_to(:manage_national_office_remark, person)
        expect(ability).not_to be_able_to(:manage_section_remarks, person)
      end
    end

    context "as employee" do
      it "is permitted to manage geschaeftsstelle remark but not section" do
        expect(ability).to be_able_to(:show_remarks, person)
        expect(ability).to be_able_to(:manage_national_office_remark, person)
        expect(ability).to be_able_to(:manage_section_remarks, person)
      end
    end

    context "as section functionary" do
      before do
        person.roles.destroy_all
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it "is permitted to manage section remarks but not geschaeftsstelle" do
        expect(ability).to be_able_to(:show_remarks, person)
        expect(ability).not_to be_able_to(:manage_national_office_remark, person)
        expect(ability).to be_able_to(:manage_section_remarks, person)
      end
    end
  end

  %i[history show_full show_details index_notes log security].each do |action|
    describe "#{action} on person without roles" do
      let(:person_without_roles) { Fabricate(:person) }

      context "backoffice role with read_all_people" do
        let(:person) {
          Fabricate(Group::Geschaeftsstelle::Mitarbeiter.sti_name,
            group: groups(:geschaeftsstelle)).person
        }

        it "may #{action}" do
          expect(ability).to be_able_to(action, person_without_roles)
        end
      end

      context "other role with read_all_people" do
        let(:group) { Fabricate(Group::Geschaeftsleitung.sti_name, parent: groups(:root)) }
        let(:person) {
          Fabricate(Group::Geschaeftsleitung::Geschaeftsfuehrung.sti_name, group: group).person
        }

        it "may not #{action}" do
          expect(ability).not_to be_able_to(action, person_without_roles)
        end
      end
    end
  end

  describe "log" do
    context "as mitglied" do
      let(:person) { mitglied }

      it "may not view his own log" do
        expect(ability).not_to be_able_to(:log, person)
      end

      it "may view his own log if he has a backoffice role" do
        Fabricate(Group::Geschaeftsstelle::MitarbeiterLesend.sti_name,
          group: groups(:geschaeftsstelle), person: mitglied)
        expect(ability).to be_able_to(:log, person)
      end
    end

    [Group::Geschaeftsstelle::Mitarbeiter, Group::Geschaeftsstelle::MitarbeiterLesend,
      Group::Geschaeftsstelle::Admin].each do |role_type|
      context role_type do
        let(:person) { Fabricate(role_type.sti_name, group: groups(:geschaeftsstelle)).person }

        it "may view mitglied's log" do
          expect(ability).to be_able_to(:log, person)
        end
      end
    end
  end

  [:index_external_invoices, :create_membership_invoice, :create_abo_magazin_invoice,
    :cancel_external_invoice, :security].each do |action|
    describe action do
      let(:person) { people(:mitglied) }

      context "as employee" do
        [Group::Geschaeftsstelle::Mitarbeiter, Group::Geschaeftsstelle::Admin].each do |role_type|
          context role_type do
            let(:person) { Fabricate(role_type.sti_name, group: groups(:geschaeftsstelle)).person }

            it "is permitted to #{action} of other people" do
              expect(ability).to be_able_to(action, mitglied)
            end

            it "is permitted to #{action} of yourself" do
              expect(ability).to be_able_to(action, person)
            end
          end
        end
      end

      context "as member" do
        it "is not permitted to #{action} yourself" do
          expect(ability).not_to be_able_to(action, person)
        end
      end

      context "as a group leader" do
        let(:person) do
          Fabricate(Group::SektionsFunktionaere::Administration.sti_name,
            group: groups(:bluemlisalp_funktionaere)).person
        end

        it "is not permitted to #{action} of yourself" do
          expect(ability).not_to be_able_to(action, person)
        end

        it "is not permitted to #{action} of other people" do
          expect(ability).not_to be_able_to(action, mitglied)
        end
      end
    end
  end

  describe "query" do
    let(:person) { mitglied }
    let(:kommission_touren) { groups(:bluemlisalp_kommission_touren) }

    it "is not allowed for regular mitglied" do
      expect(ability).not_to be_able_to(:query, Person)
    end

    it "is allowed with layer_events_full permission" do
      Group::SektionsKommissionTouren::Mitglied.create!(group: kommission_touren,
        person: person)
      expect(ability).to be_able_to(:query, Person)
    end
  end
end
