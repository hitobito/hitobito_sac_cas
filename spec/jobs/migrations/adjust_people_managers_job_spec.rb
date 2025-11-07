# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::AdjustPeopleManagersJob do
  let(:job) { described_class.new }

  let(:main_person) { people(:familienmitglied) }
  let(:other_adult) { people(:familienmitglied2) }
  let(:child) { people(:familienmitglied_kind) }

  it "does nothing if managers are allright" do
    existing = main_person.people_manageds
    expect(existing.count).to eq(2)

    expect { job.perform }.not_to change { PeopleManager.count }

    expect(PeopleManager.where(id: existing.map(&:id)).count).to eq(2)
  end

  it "removes manageds from other adult and adds manager to main person" do
    existing = PeopleManager.find_by(manager: main_person, managed: child)
    PeopleManager.find_by(manager: main_person, managed: other_adult).destroy!
    PeopleManager.create!(manager: other_adult, managed: child)

    expect { job.perform }.not_to change { PeopleManager.count }

    expect(PeopleManager.where(id: existing.id)).to be_exists
    expect(PeopleManager.where(manager: main_person, managed: other_adult)).to be_exists
    expect(PeopleManager.where(manager: other_adult, managed: child)).not_to be_exists
  end

  it "add people managers if missing completely" do
    PeopleManager.where(manager: main_person).destroy_all

    expect { job.perform }.to change { PeopleManager.count }.by(2)

    expect(PeopleManager.where(manager: main_person, managed: other_adult)).to be_exists
    expect(PeopleManager.where(manager: main_person, managed: child)).to be_exists
  end
end
