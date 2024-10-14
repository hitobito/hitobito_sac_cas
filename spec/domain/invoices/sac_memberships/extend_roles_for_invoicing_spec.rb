# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::ExtendRolesForInvoicing do
  subject(:extend_roles) { described_class.new(date).extend_roles }

  let(:person) { people(:mitglied) }
  let!(:person_mitglied_role) { person.roles.with_inactive.first.tap { |r| r.update!(end_on: 1.year.ago) } }
  let(:date) { 1.week.from_now.to_date }

  context "with role" do
    it "extends the role" do
      expect { extend_roles }.to change { person_mitglied_role.reload.end_on }.to(date)
    end
  end

  context "with multiple people and roles" do
    let!(:person_ehrenmitglied_role) do
      person.roles.create!(group: person.groups.first, created_at: 2.days.ago, end_on: 1.day.ago,
        type: Group::SektionsMitglieder::Ehrenmitglied.sti_name)
    end
    let(:other_person) { people(:familienmitglied) }
    let!(:other_person_role) { other_person.roles.first.tap { |r| r.update!(end_on: 1.year.ago) } }

    it "extends roles" do
      expect { extend_roles }
        .to change { person_mitglied_role.reload.end_on }.to(date)
        .and change { person_ehrenmitglied_role.reload.end_on }.to(date)
        .and change { other_person_role.reload.end_on }.to(date)
    end

    it "only makes 3 database queries" do
      expect_query_count { extend_roles }.to eq(3) # SELECT in batches (2x) and UPDATE all (1x)
    end
  end

  it "doesnt extend terminated role" do
    person_mitglied_role.update!(end_on: 1.year.from_now) # role can't be ended to be allowed to terminate
    expect(Roles::Termination.new(role: person_mitglied_role, terminate_on: 1.day.from_now).call).to be_truthy
    expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
  end

  context "with role#end_on at date" do
    before { person_mitglied_role.update!(end_on: date) }

    it "doesnt extend the role" do
      expect { extend_roles }.not_to change { person_mitglied_role.reload.end_on }
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
end
