# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::AccountCompletionList do
  let(:host) { "http://localhost:3000" }
  let(:scope) { Person.where(id: [admin.id, mitglied.id]) }
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:list) { described_class.new }

  def find_by_token(url)
    Person.find_by_token_for(:account_completion, url.split("=").last)
  end

  it "generates csv data with person_id and account_completion_url" do
    csv = CSV.parse(list.generate(scope, host:), headers: true)
    expect(csv.headers).to eq %w[person_id url]
    expect(csv.entries).to have(2).items
    expect(csv[0]["person_id"]).to eq "600000"
    expect(csv[1]["person_id"]).to eq "600001"
    expect(csv[0]["url"]).to start_with("http://localhost:3000/account_completion?token=")
    expect(csv[1]["url"]).to start_with("http://localhost:3000/account_completion?token=")
    expect(find_by_token(csv[0]["url"])).to eq admin
    expect(find_by_token(csv[1]["url"])).to eq mitglied
  end

  it "re-running generates new tokens" do
    csv_one = CSV.parse(list.generate(scope, host:), headers: true)
    csv_two = CSV.parse(list.generate(scope, host:), headers: true)
    expect(csv_one[0]["person_id"]).to eq csv_two[0]["person_id"]
    expect(csv_one[0]["url"]).not_to eq csv_two[0]["url"]
    expect(find_by_token(csv_one[0]["url"])).to eq admin
    expect(find_by_token(csv_two[0]["url"])).to eq admin
  end
end
