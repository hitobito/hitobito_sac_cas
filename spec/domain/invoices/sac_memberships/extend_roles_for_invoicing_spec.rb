# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::ExtendRolesForInvoicing do
  include Households::SpecHelper
  subject(:extend_roles) { described_class.new(date, reference_date).extend_roles }

  let(:person) { people(:mitglied) }
  let(:person_mitglied_role) { roles(:mitglied) }
  let(:date) { 1.year.from_now.to_date }
  let(:reference_date) { Time.zone.now.to_date }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }

  before { set_end_on_for_all_roles(person) }

  context "with role" do
    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(date)
    end
  end

  context "with multiple people and roles" do
    let!(:person_ehrenmitglied_role) do
      person.roles.create!(group: groups(:bluemlisalp_mitglieder), created_at: 2.days.ago, end_on: 1.month.from_now, start_on: nil,
        type: Group::SektionsMitglieder::Ehrenmitglied.sti_name)
    end
    let(:other_person) { people(:familienmitglied) }

    before { set_end_on_for_all_roles(other_person) }

    it "extends roles" do
      expect { extend_roles }
        .to change { person_mitglied_role.reload.end_on }.to(date)
        .and change { person_ehrenmitglied_role.reload.end_on }.to(date)
        .and change { other_person.roles.reload.map(&:end_on) }.to([date, date])
    end

    it "only makes 5 database queries" do
      expect_query_count { extend_roles }.to eq(5) # SELECT in batches (2x) and SELECT for beitragskategorie change (2x) and UPDATE all (1x)
    end

    context "with multiple batches and various roles" do
      it "extends all roles" do
        # Zusatzsektion Mitglied Roles are updated in another batch,
        # after stammsektion roles have already been updated
        stub_const("#{described_class.name}::BATCH_SIZE", 2)
        person_mitglied_role.update_column(:id, 10)
        roles(:familienmitglied).update_column(:id, 11)
        person_ehrenmitglied_role.update_column(:id, 12)
        roles(:mitglied_zweitsektion).update_column(:id, 21)
        roles(:familienmitglied_zweitsektion).update_column(:id, 23)

        expect { extend_roles }
          .to change { person.roles.reload.map(&:end_on) }.to([date, date, date])
          .and change { other_person.roles.reload.map(&:end_on) }.to([date, date])
      end
    end
  end

  it "doesnt extend terminated role" do
    person_mitglied_role.update!(end_on: 1.year.from_now) # role can't be ended to be allowed to terminate
    expect(Roles::Termination.new(role: person_mitglied_role, terminate_on: 1.day.from_now).call).to be_truthy
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  context "with role#end_on at date" do
    before { person.roles.update_all(end_on: date) }

    let(:count) { (date.year == Time.zone.today.year) ? 3 : 5 }

    it "doesnt extend the role" do
      expect { expect_query_count { extend_roles }.to eq(count) }.not_to change { person_mitglied_role.reload.end_on }
    end
  end

  context "with role#end_on after date" do
    before { person_mitglied_role.update!(end_on: date + 1.week) }

    it "doesnt extend the role" do
      expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
    end
  end

  context "with person#data_quality errors" do
    before { person.update!(data_quality: :error) }

    it "doesnt extend the role" do
      expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
    end
  end

  context "with invoice the same year as the specified date" do
    before { ExternalInvoice::SacMembership.create!(person: person, year: date.year) }

    it "doesnt extend the role" do
      expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
    end
  end

  context "with invoice in a different year" do
    before { ExternalInvoice::SacMembership.create!(person: person, year: date.year.next) }

    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(date)
    end
  end

  describe "convert roles to youth" do
    let!(:person_turned_youth) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", beitragskategorie: :family, email: "dad@hitobito.example.com", confirmed_at: Time.current, sac_family_main_person: true, end_on: 1.month.from_now) }

    context "stammsektion role" do
      it "creates youth role for family with reference age equal 18" do
        person_turned_youth.update!(birthday: reference_date - 18.years)

        expect { extend_roles }.to change { person_turned_youth.roles.future.count }.to(1)

        new_role = person_turned_youth.roles.future.reload.last
        expect(new_role.beitragskategorie).to eq("youth")
        expect(new_role.start_on).to eq(reference_date + 1.day)
        expect(new_role.end_on).to eq(date)
      end

      it "creates youth role for family with reference age above 18" do
        person_turned_youth.update!(birthday: reference_date - 18.years - 1.day)

        expect { extend_roles }.to change { person_turned_youth.roles.future.count }.to(1)

        new_role = person_turned_youth.roles.future.reload.last
        expect(new_role.beitragskategorie).to eq("youth")
        expect(new_role.start_on).to eq(reference_date + 1.day)
        expect(new_role.end_on).to eq(date)
      end

      it "does not create youth role for family with reference age below 18" do
        person_turned_youth.update!(birthday: reference_date - 18.years + 1.day)

        expect { extend_roles }.to_not change { person_turned_youth.roles.count }
      end
    end

    context "zusatzsektion role" do
      it "creates role for family zusatzsektion role" do
        person_turned_youth.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: person_turned_youth, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :family)

        expect { extend_roles }.to change { person_turned_youth.sac_membership.zusatzsektion_roles.future.count }.to(1)

        zusatzsektion_role = person_turned_youth.sac_membership.zusatzsektion_roles.future.last
        expect(zusatzsektion_role).to be_present
        expect(zusatzsektion_role.beitragskategorie).to eq("adult") # stimmt das? Kommt von FamilyMutation
        expect(zusatzsektion_role.start_on).to eq(reference_date + 1.day)
        expect(zusatzsektion_role.end_on).to eq(date)
      end

      it "does not create role for adult zusatzsektion role" do
        person_turned_youth.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: person_turned_youth, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :adult)

        expect { extend_roles }.to_not change { person_turned_youth.sac_membership.zusatzsektion_roles.count }
      end
    end

    context "dissolving household" do
      let!(:person_turned_youth) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", beitragskategorie: :adult, email: "dad@hitobito.example.com", confirmed_at: Time.current, sac_family_main_person: true) }
      let!(:other) { Fabricate(:person, birthday: 24.years.ago) }

      before do
        create_household(person_turned_youth, other)
        membership_roles = Group::SektionsMitglieder::Mitglied.where(person: [person_turned_youth, other], beitragskategorie: :family)
        membership_roles.update_all(start_on: 1.month.ago, end_on: 1.month.from_now)
      end

      it "replaces family membership role for other with adult membership" do
        person_turned_youth.update!(birthday: reference_date - 18.years)

        expect { extend_roles }.to change { other.roles.future.count }.to(1)

        # household keys should still be present since the household should only be completely
        # dissolved on the reference_date. At that point the
        # DestroyHouseholdsForInactiveMembershipsJob will take care of that.
        expect(person_turned_youth.reload.household_key).to be_present
        expect(other.reload.household_key).to be_present
      end
    end
  end

  describe "convert roles to adult" do
    let!(:person_turned_adult) { Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied", beitragskategorie: :youth, email: "dad@hitobito.example.com", confirmed_at: Time.current, end_on: 1.month.from_now) }

    context "stammsektion role" do
      it "creates adult role for youth with reference age equal 23" do
        person_turned_adult.update!(birthday: reference_date - 23.years)

        expect { extend_roles }.to change { person_turned_adult.roles.future.count }.to(1)

        new_role = person_turned_adult.roles.future.last
        expect(new_role.beitragskategorie).to eq("adult")
        expect(new_role.start_on).to eq(reference_date + 1.day)
        expect(new_role.end_on).to eq(date)
      end

      it "creates adult role for youth with reference age above 23" do
        person_turned_adult.update!(birthday: reference_date - 23.years - 1.day)

        expect { extend_roles }.to change { person_turned_adult.roles.future.count }.to(1)

        new_role = person_turned_adult.roles.future.last
        expect(new_role.beitragskategorie).to eq("adult")
        expect(new_role.start_on).to eq(reference_date + 1.day)
        expect(new_role.end_on).to eq(date)
      end

      it "does not create adult role for youth with reference age below 23" do
        person_turned_adult.update!(birthday: reference_date - 23.years + 1.day)

        expect { extend_roles }.to_not change { person_turned_adult.roles.count }
      end
    end

    context "zusatzsektion role" do
      it "creates role for youth zusatzsektion role" do
        person_turned_adult.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: person_turned_adult, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :youth)

        expect { extend_roles }.to change { person_turned_adult.sac_membership.zusatzsektion_roles.future.count }.to(1)

        zusatzsektion_role = person_turned_adult.roles.future.where(type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, beitragskategorie: :adult).last
        expect(zusatzsektion_role).to be_present
        expect(zusatzsektion_role.beitragskategorie).to eq("adult")
        expect(zusatzsektion_role.start_on).to eq(reference_date + 1.day)
        expect(zusatzsektion_role.end_on).to eq(date)
      end

      it "does not create role for adult zusatzsektion role" do
        person_turned_adult.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: person_turned_adult, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :adult)

        expect { extend_roles }.to_not change { person_turned_adult.sac_membership.zusatzsektion_roles.count }
      end
    end
  end

  def set_end_on_for_all_roles(person)
    person.roles.with_inactive.each { |r| r.update!(end_on: 1.month.from_now) }
  end
end
