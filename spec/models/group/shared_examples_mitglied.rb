# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "validates Mitglied timestamps" do
  it "created_at is required" do
    role = described_class.new(person: people(:mitglied))
    role.validate
    expect(role.errors[:created_at]).to include("muss ausgefüllt werden")

    role.created_at = Time.zone.now
    role.validate
    expect(role.errors[:created_at]).to be_empty
  end

  it "delete_on is required if deleted_at is blank" do
    role = described_class.new(person: people(:mitglied))
    role.validate
    expect(role.errors[:delete_on]).to include("muss vorhanden sein, wenn nicht gelöscht.")

    role.delete_on = Time.zone.today
    role.validate
    expect(role.errors[:delete_on]).to be_empty

    role.delete_on = nil
    role.deleted_at = Time.zone.now
    role.validate
    expect(role.errors[:delete_on]).to be_empty
  end
end
