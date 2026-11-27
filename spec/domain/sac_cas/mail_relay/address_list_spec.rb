# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailRelay::AddressList do
  let(:manager) { people(:familienmitglied) }
  let(:child) { people(:familienmitglied_kind) }
  let(:other_parent) { people(:familienmitglied2) }

  def person_emails(people) = described_class.new(people).person_emails

  it "uses only the email of a managed person with email" do
    expect(person_emails([child])).to eq([{person_id: child.id, email: child.email}])
  end

  it "uses the manager emails for a managed person without email" do
    child.update_columns(email: nil)
    e1 = Fabricate(:additional_email, contactable: manager, mailings: true)

    expect(person_emails([child])).to match_array([
      {person_id: manager.id, email: manager.email},
      {person_id: manager.id, email: e1.email}
    ])
  end

  it "lists a manager only once when also selected" do
    child.update_columns(email: nil)

    expect(person_emails([manager, child])).to eq([{person_id: manager.id, email: manager.email}])
  end

  it "loads managers of several people without email in constant queries" do
    child.update_columns(email: nil)
    other_parent.update_columns(email: nil)

    one = QueryHelpers.count_queries { person_emails([child]) }.count
    two = QueryHelpers.count_queries { person_emails([child, other_parent]) }.count

    expect(two).to eq(one)
    expect(person_emails([child, other_parent])).to eq([{person_id: manager.id, email: manager.email}])
  end

  it "returns plain emails without duplicates" do
    child.update_columns(email: nil)
    other_parent.update_columns(email: nil)

    expect(described_class.new([child, other_parent]).emails).to eq([manager.email])
  end
end
