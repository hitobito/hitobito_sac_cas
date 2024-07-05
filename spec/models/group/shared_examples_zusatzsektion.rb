# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "requires a concurrently active mitglied role" do |zusatzsektion_type|
  it do
    person = Fabricate(:person)
    zusatz_role = Fabricate.build(
      zusatzsektion_type.sti_name,
      person: person,
      group: groups(:bluemlisalp_mitglieder),
      created_at: 1.month.ago,
      delete_on: 1.month.from_now
    )

    expect(zusatz_role).not_to be_valid
    expect(zusatz_role.errors[:person]).to eq ["muss Mitglied sein während der ganzen Gültigkeitsdauer der Zusatzsektion."]

    mitglied_role = Fabricate(
      Group::SektionsMitglieder::Mitglied.name,
      person: person,
      group: groups(:matterhorn_mitglieder),
      created_at: 3.month.ago,
      delete_on: 2.month.ago
    )
    expect(zusatz_role).not_to be_valid

    mitglied_role.update!(delete_on: 1.month.from_now)
    expect(zusatz_role).to be_valid
  end
end
