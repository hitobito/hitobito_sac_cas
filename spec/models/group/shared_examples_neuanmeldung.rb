# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "validates Neuanmeldung timestamps" do
  it "start_on is required" do
    role = described_class.new(person: people(:mitglied))
    role.validate
    expect(role.errors[:start_on]).to include("muss ausgefüllt werden")

    role.start_on = Date.current
    role.validate
    expect(role.errors[:start_on]).to be_empty
  end

  it "delete_on is not required" do
    role = described_class.new(person: people(:mitglied), end_on: nil)
    role.validate
    expect(role.errors[:end_on]).to be_empty
  end
end
