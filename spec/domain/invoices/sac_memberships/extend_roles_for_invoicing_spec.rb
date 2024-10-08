# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::ExtendRolesForInvoicing do
  subject(:extend_roles) { described_class.new(date).extend_roles }

  let!(:person) { people(:mitglied).tap { |p| p.roles.first.update!(delete_on: 1.year.ago) } }
  let(:date) { 1.week.from_now.to_date }

  context "with role" do
    it "extends the role" do
      expect { extend_roles }.to change { person.roles.first.delete_on }.to(date)
    end
  end

  context "with multiple people and roles" do
    let!(:member) { people(:familienmitglied).tap { |p| p.roles.first.update!(delete_on: 1.year.ago) } }
    let!(:role) do
      person.roles.create!(group: person.groups.first, created_at: 2.days.ago, delete_on: 1.day.ago,
        type: Group::SektionsMitglieder::Ehrenmitglied.sti_name)
    end

    it "extends roles" do
      expect { extend_roles }
        .to change { person.roles.first.delete_on }.to(date)
        .and change { member.roles.first.delete_on }.to(date)
        .and change { role.reload.delete_on }.to(date)
    end

    it "only makes 3 database queries" do
      expect_query_count { extend_roles }.to eq(3) # SELECT in batches (2x) and UPDATE all (1x)
    end
  end

  context "without required role" do
    before { person.roles.first.destroy! }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with terminated role" do
    before { Roles::Termination.new(role: person.roles.first, terminate_on: 1.day.from_now).call }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with role#delete_on at date" do
    before { person.roles.first.update!(delete_on: date) }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with role#delete_on after date" do
    before { person.roles.first.update!(delete_on: date + 1.week) }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with person#data_quality errors" do
    before { person.update!(data_quality: :error) }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with invoice the same year as the specified date" do
    before { ExternalInvoice::SacMembership.create!(person: person, year: date.year) }

    it "doesn't extend the role" do
      expect { extend_roles }.not_to change { person.roles.first.delete_on }
    end
  end

  context "with invoice in a different year" do
    before { ExternalInvoice::SacMembership.create!(person: person, year: date.year.next) }

    it "extends the role" do
      expect { extend_roles }.to change { person.roles.first.delete_on }.to(date)
    end
  end
end
