# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::ExtendRolesForInvoicing do
  include Households::SpecHelper
  subject(:extend_roles) { described_class.new(prolongation_date, new_role_start_on).extend_roles }

  let(:person) { people(:mitglied) }
  let(:person_mitglied_role) { roles(:mitglied) }
  let(:prolongation_date) { reference_date + 1.year }
  let(:reference_date) { Time.zone.now.to_date }
  let(:new_role_start_on) { reference_date - 1.year + 1.day }
  let(:old_role_end_on) { new_role_start_on - 1.day }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }

  before { set_end_on_for_all_roles(person) }

  context "with role" do
    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(prolongation_date)
    end
  end

  context "with multiple people and roles" do
    let!(:person_ehrenmitglied_role) do
      # rubocop:todo Layout/LineLength
      person.roles.create!(group: groups(:bluemlisalp_mitglieder), created_at: 2.days.ago, end_on: 1.month.from_now, start_on: nil,
        # rubocop:enable Layout/LineLength
        type: Group::SektionsMitglieder::Ehrenmitglied.sti_name)
    end
    let(:other_person) { people(:familienmitglied) }

    before { set_end_on_for_all_roles(other_person) }

    it "extends roles" do
      expect { extend_roles }
        .to change { person_mitglied_role.reload.end_on }.to(prolongation_date)
        .and change { person_ehrenmitglied_role.reload.end_on }.to(prolongation_date)
        .and change {
               other_person.roles.reload.map(&:end_on)
             }.to([prolongation_date, prolongation_date])
    end

    it "only makes 5 database queries" do
      expect_query_count {
        # rubocop:todo Layout/LineLength
        extend_roles
      }.to eq(5) # SELECT in batches (2x) and SELECT for beitragskategorie change (2x) and UPDATE all (1x)
      # rubocop:enable Layout/LineLength
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
          .to change {
                person.roles.reload.map(&:end_on)
              }.to([prolongation_date, prolongation_date, prolongation_date])
          .and change {
                 other_person.roles.reload.map(&:end_on)
               }.to([prolongation_date, prolongation_date])
      end
    end
  end

  it "doesnt extend terminated role" do
    # rubocop:todo Layout/LineLength
    person_mitglied_role.update!(end_on: prolongation_date - 1.month) # role can't be ended to be allowed to terminate
    # rubocop:enable Layout/LineLength
    expect(Roles::Termination.new(role: person_mitglied_role,
      terminate_on: 1.day.from_now).call).to be_truthy
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  # rubocop:todo Layout/LineLength
  it "doesnt extend role which ended before the previous years prolongation_date (reference_date - 1.day)" do
    # rubocop:enable Layout/LineLength
    person_mitglied_role.update!(end_on: new_role_start_on - 2.days)
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  it "doesnt extend role which ended before after prolongation_date" do
    person_mitglied_role.update!(end_on: prolongation_date + 1.day)
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  it "doesnt extend role if person has a future extendable role after reference date" do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person: person,
      group: bluemlisalp_mitglieder, start_on: reference_date + 2.months, end_on: prolongation_date)
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  it "does extend role if another person has a future extendable role after reference date" do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: bluemlisalp_mitglieder,
      start_on: reference_date + 2.months, end_on: prolongation_date)
    expect { extend_roles }.to change { person_mitglied_role.reload.end_on }
  end

  it "extends role if person has a future extendable role before reference date" do
    Fabricate(Group::AboMagazin::Abonnent.sti_name, person: person, group: groups(:abo_die_alpen),
      start_on: reference_date - 1.months, end_on: 1.year.from_now)
    expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(prolongation_date)
  end

  it "extends role if person has a future non extendable role" do
    Fabricate(Group::AboMagazin::Abonnent.sti_name, person: person, group: groups(:abo_die_alpen),
      start_on: reference_date + 2.months, end_on: 1.year.from_now)
    expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(prolongation_date)
  end

  context "with role#end_on at date" do
    before { person.roles.update_all(end_on: prolongation_date) }

    let(:count) { (prolongation_date.year == Time.zone.today.year) ? 3 : 5 }

    it "doesnt extend the role" do
      expect { expect_query_count { extend_roles }.to eq(count) }.not_to change {
        person_mitglied_role.reload.end_on
      }
    end
  end

  context "with role#end_on after prolongation_date" do
    before { person_mitglied_role.update!(end_on: prolongation_date + 1.week) }

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

  context "with invoice the same year as the specified prolongation_date" do
    before { ExternalInvoice::SacMembership.create!(person: person, year: prolongation_date.year) }

    it "doesnt extend the role" do
      expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
    end
  end

  context "with invoice in a different year" do
    before {
      ExternalInvoice::SacMembership.create!(person: person, year: prolongation_date.year.next)
    }

    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(prolongation_date)
    end
  end

  describe "convert roles to youth" do
    let!(:person_turned_youth) {
      Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied",
        # rubocop:todo Layout/LineLength
        beitragskategorie: :family, email: "dad@hitobito.example.com", birthday: reference_date - 18.years, confirmed_at: Time.current, sac_family_main_person: true, end_on: 1.month.from_now)
      # rubocop:enable Layout/LineLength
    }
    let!(:previous_membership_role) { person_turned_youth.roles.first }

    context "stammsektion role" do
      it "creates youth role for family with reference age equal 18" do
        expect { extend_roles }.to change { person_turned_youth.roles.with_inactive.count }.by(1)

        expect(previous_membership_role.reload.end_on).to eq(old_role_end_on)

        new_role = person_turned_youth.roles.active.reload.last
        expect(new_role.beitragskategorie).to eq("youth")
        expect(new_role.start_on).to eq(new_role_start_on)
        expect(new_role.end_on).to eq(prolongation_date)
      end

      it "creates youth role for family with reference age above 18" do
        person_turned_youth.update!(birthday: reference_date - 18.years - 1.day)

        expect { extend_roles }.to change { person_turned_youth.roles.with_inactive.count }.by(1)

        expect(previous_membership_role.reload.end_on).to eq(old_role_end_on)

        new_role = person_turned_youth.roles.active.reload.last
        expect(new_role.beitragskategorie).to eq("youth")
        expect(new_role.start_on).to eq(new_role_start_on)
        expect(new_role.end_on).to eq(prolongation_date)
      end

      it "does not create youth role for family with reference age below 18" do
        person_turned_youth.update!(birthday: reference_date - 18.years + 1.day)

        expect { extend_roles }.to_not change { person_turned_youth.roles.count }
      end

      # rubocop:todo Layout/LineLength
      it "does not create youth role for family if they already have a future extendable role after reference date" do
        # rubocop:enable Layout/LineLength
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person: person_turned_youth,
          # rubocop:todo Layout/LineLength
          group: bluemlisalp_mitglieder, start_on: reference_date + 2.months, end_on: 1.year.from_now)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to_not change { person_turned_youth.roles.count }
      end

      it "creates youth role for family if they have a future non extendable role" do
        expect { extend_roles }.to change { person_turned_youth.roles.with_inactive.count }.by(1)
      end

      # rubocop:todo Layout/LineLength
      it "does not create youth role for family if their membership is longer than the prolongation date" do
        # rubocop:enable Layout/LineLength
        person_turned_youth.roles.first.update!(end_on: prolongation_date + 1.day)

        expect { extend_roles }.to_not change { person_turned_youth.roles.count }
      end
    end

    context "zusatzsektion role" do
      it "creates role for family zusatzsektion role" do
        person_turned_youth.update!(birthday: reference_date - 23.years)
        # rubocop:todo Layout/LineLength
        previous_zusatzsektion_role = Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          # rubocop:enable Layout/LineLength
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          # rubocop:todo Layout/LineLength
          person: person_turned_youth, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :family)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to change {
          person_turned_youth.sac_membership.zusatzsektion_roles.with_inactive.count
        }.by(1)

        expect(previous_zusatzsektion_role.reload.end_on).to eq(old_role_end_on)

        zusatzsektion_role = person_turned_youth.sac_membership.zusatzsektion_roles.active.last
        expect(zusatzsektion_role).to be_present
        # rubocop:todo Layout/LineLength
        expect(zusatzsektion_role.beitragskategorie).to eq("adult") # stimmt das? Kommt von FamilyMutation
        # rubocop:enable Layout/LineLength
        expect(zusatzsektion_role.start_on).to eq(new_role_start_on)
        expect(zusatzsektion_role.end_on).to eq(prolongation_date)
      end

      it "does not create role for adult zusatzsektion role" do
        person_turned_youth.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          # rubocop:todo Layout/LineLength
          person: person_turned_youth, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :adult)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to_not change {
          person_turned_youth.sac_membership.zusatzsektion_roles.count
        }
      end
    end

    context "dissolving household" do
      let!(:person_turned_youth) {
        Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied",
          # rubocop:todo Layout/LineLength
          beitragskategorie: :adult, email: "dad@hitobito.example.com", confirmed_at: Time.current, sac_family_main_person: true)
        # rubocop:enable Layout/LineLength
      }
      let!(:other) { Fabricate(:person, birthday: reference_date - 24.years) }

      before do
        create_household(person_turned_youth, other)
        membership_roles = Group::SektionsMitglieder::Mitglied.where(
          person: [person_turned_youth, other], beitragskategorie: :family
        )
        person_turned_youth.roles.ended.update_all(end_on: new_role_start_on - 1.month)
        membership_roles.update_all(start_on: new_role_start_on - 1.month, end_on: 1.month.from_now)
      end

      it "replaces family membership role for other with adult membership" do
        person_turned_youth.update!(birthday: reference_date - 18.years)

        expect { extend_roles }.to change { other.roles.with_inactive.count }.by(1)

        # household keys should still be present since the household should only be completely
        # dissolved on the reference_date. At that point the
        # DestroyHouseholdsForInactiveMembershipsJob will take care of that.
        expect(person_turned_youth.reload.household_key).to be_present
        expect(other.reload.household_key).to be_present
      end

      context "with multiple turned youth members" do
        let!(:second_person_turned_youth) {
          Fabricate(:person_with_role, group: bluemlisalp_mitglieder,
            role: "Mitglied", beitragskategorie: :adult,
            email: "sister@hitobito.example.com", confirmed_at: Time.current,
            birthday: reference_date - 14.years)
        }

        before do
          create_household(person_turned_youth, second_person_turned_youth, other)
          membership_roles = Group::SektionsMitglieder::Mitglied.where(person: [person_turned_youth,
            second_person_turned_youth, other],
            beitragskategorie: :family)
          person_turned_youth.roles.ended.update_all(end_on: new_role_start_on - 1.month)
          second_person_turned_youth.roles.ended.update_all(end_on: new_role_start_on - 1.month)
          membership_roles.update_all(start_on: new_role_start_on - 1.month, end_on: 1.month.from_now)
        end

        it "replaces family membership role for other with adult membership" do
          person_turned_youth.update!(birthday: reference_date - 18.years)
          second_person_turned_youth.update!(birthday: reference_date - 18.years)

          expect { extend_roles }.to change { other.roles.with_inactive.count }.by(1)

          # household keys should still be present since the household should only be completely
          # dissolved on the reference_date. At that point the
          # DestroyHouseholdsForInactiveMembershipsJob will take care of that.
          expect(person_turned_youth.reload.household_key).to be_present
          expect(other.reload.household_key).to be_present
        end
      end
    end
  end

  describe "convert roles to adult" do
    let!(:person_turned_adult) {
      Fabricate(:person_with_role, group: bluemlisalp_mitglieder, role: "Mitglied",
        # rubocop:todo Layout/LineLength
        beitragskategorie: :youth, email: "dad@hitobito.example.com", birthday: reference_date - 23.years, confirmed_at: Time.current, end_on: 1.month.from_now)
      # rubocop:enable Layout/LineLength
    }
    let!(:previous_membership_role) { person_turned_adult.roles.first }

    context "stammsektion role" do
      it "creates adult role for youth with reference age equal 23" do
        expect { extend_roles }.to change { person_turned_adult.roles.with_inactive.count }.by(1)

        expect(previous_membership_role.reload.end_on).to eq(old_role_end_on)

        new_role = person_turned_adult.roles.active.last
        expect(new_role.beitragskategorie).to eq("adult")
        expect(new_role.start_on).to eq(new_role_start_on)
        expect(new_role.end_on).to eq(prolongation_date)
      end

      it "creates adult role for youth with reference age above 23" do
        person_turned_adult.update!(birthday: reference_date - 23.years - 1.day)

        expect { extend_roles }.to change { person_turned_adult.roles.with_inactive.count }.by(1)

        expect(previous_membership_role.reload.end_on).to eq(old_role_end_on)

        new_role = person_turned_adult.roles.active.last
        expect(new_role.beitragskategorie).to eq("adult")
        expect(new_role.start_on).to eq(new_role_start_on)
        expect(new_role.end_on).to eq(prolongation_date)
      end

      it "does not create adult role for youth with reference age below 23" do
        person_turned_adult.update!(birthday: reference_date - 23.years + 1.day)

        expect { extend_roles }.to_not change { person_turned_adult.roles.count }
      end

      it "does not create adult role for youth with future extendable role" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, person: person_turned_adult,
          # rubocop:todo Layout/LineLength
          group: bluemlisalp_mitglieder, start_on: reference_date + 2.months, end_on: 1.year.from_now)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to_not change { person_turned_adult.roles.count }
      end

      # rubocop:todo Layout/LineLength
      it "does not create adult role for youth if their membership is longer than the prolongation date" do
        # rubocop:enable Layout/LineLength
        person_turned_adult.roles.first.update!(end_on: prolongation_date + 1.day)

        expect { extend_roles }.to_not change { person_turned_adult.roles.count }
      end
    end

    context "zusatzsektion role" do
      it "creates role for youth zusatzsektion role" do
        person_turned_adult.update!(birthday: reference_date - 23.years)
        # rubocop:todo Layout/LineLength
        previous_zusatzsektion_role = Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          # rubocop:enable Layout/LineLength
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          # rubocop:todo Layout/LineLength
          person: person_turned_adult, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :youth)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to change {
          person_turned_adult.sac_membership.zusatzsektion_roles.with_inactive.count
        }.by(1)

        expect(previous_zusatzsektion_role.reload.end_on).to eq(old_role_end_on)

        zusatzsektion_role = person_turned_adult.roles.active.where(
          # rubocop:todo Layout/LineLength
          type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, beitragskategorie: :adult
          # rubocop:enable Layout/LineLength
        ).last
        expect(zusatzsektion_role).to be_present
        expect(zusatzsektion_role.beitragskategorie).to eq("adult")
        expect(zusatzsektion_role.start_on).to eq(new_role_start_on)
        expect(zusatzsektion_role.end_on).to eq(prolongation_date)
      end

      it "does not create role for adult zusatzsektion role" do
        person_turned_adult.update!(birthday: reference_date - 23.years)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          # rubocop:todo Layout/LineLength
          person: person_turned_adult, start_on: 1.year.ago, end_on: 1.month.from_now, beitragskategorie: :adult)
        # rubocop:enable Layout/LineLength

        expect { extend_roles }.to_not change {
          person_turned_adult.sac_membership.zusatzsektion_roles.count
        }
      end
    end
  end

  def set_end_on_for_all_roles(person)
    person.roles.with_inactive.each { |r| r.update!(end_on: 1.month.from_now) }
  end
end
