#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Synchronize::Mailchimp::Subscriber do
  subject(:subscriber) { described_class.new(person, person.email) }

  let(:person) { Person.new(id: 1, company: true, email: "company@example.com", company_name: "Example Ltd") }

  it "uses first and last name if present" do
    person.first_name = "Jane"
    person.last_name = "Roe"
    expect(person.first_name).to eq "Jane"
    expect(person.last_name).to eq "Roe"
  end

  it "falls back to company name if first_name is blank" do
    person.last_name = "Roe"
    expect(subscriber.first_name).to eq "Example Ltd"
    expect(subscriber.last_name).to eq "Roe"
  end

  it "falls back to company if last_name is blank" do
    expect(subscriber.first_name).to eq "Example Ltd"
    expect(subscriber.last_name).to eq "Example Ltd"
  end

  it "falls back to company_name for first and last name company_name is blank" do
    person.company_name = nil
    expect(subscriber.first_name).to be_nil
    expect(subscriber.last_name).to eq "Firma"
  end
end
