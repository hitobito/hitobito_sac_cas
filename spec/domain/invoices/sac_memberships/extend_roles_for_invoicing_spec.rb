# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::ExtendRolesForInvoicing do
  subject(:extend_roles) { described_class.new(date).extend_roles }

  let(:person) { people(:mitglied) }
  let(:person_mitglied_role) { roles(:mitglied) }
  let(:date) { 1.week.from_now.to_date }

  before { set_end_on_for_all_roles(person) }

  context "with role" do
    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(date)
    end
  end

  context "with multiple people and roles" do
    let!(:person_ehrenmitglied_role) do
      person.roles.create!(group: groups(:bluemlisalp_mitglieder), created_at: 2.days.ago, end_on: 1.day.ago, start_on: nil,
        type: Group::SektionsMitglieder::Ehrenmitglied.sti_name)
    end
    let(:other_person) { people(:familienmitglied) }

    before { set_end_on_for_all_roles(other_person) }

    it "extends roles" do
      expect { extend_roles }
        .to change { person_mitglied_role.reload.end_on }.to(date)
        .and change { person_ehrenmitglied_role.reload.end_on }.to(date)
        .and change { other_person.roles.with_inactive.map(&:end_on) }.to([date, date])
    end

    it "only makes 3 database queries" do
      expect_query_count { extend_roles }.to eq(3) # SELECT in batches (2x) and UPDATE all (1x)
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
          .to change { person.roles.with_inactive.map(&:end_on) }.to([date, date, date])
          .and change { other_person.roles.with_inactive.map(&:end_on) }.to([date, date])
      end
    end
  end

  it "doesnt extend terminated role" do
    person_mitglied_role.update!(end_on: 1.year.from_now) # role can't be ended to be allowed to terminate
    expect(Roles::Termination.new(role: person_mitglied_role, terminate_on: 1.day.from_now).call).to be_truthy
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  context "with role#end_on at date" do
    before { person.roles.with_inactive.update_all(end_on: date) }

    let(:count) { (date.year == Time.zone.today.year) ? 1 : 3 }

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

  def set_end_on_for_all_roles(person)
    person.roles.with_inactive.each { |r| r.update!(end_on: 1.year.ago) }
  end
end
