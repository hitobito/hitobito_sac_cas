# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacImports::CsvSource::Nav1 do
  let(:attrs) { described_class.members }
  let(:row) { attrs.index_by(&:itself) }

  subject(:data) { described_class.new(**row) }

  it "works with all columns" do
    attrs.each do |attr|
      expect(data.send(attr)).to eq row[attr]
    end
  end

  it "works without the last three phone columns" do
    row.delete(:phone_private)
    row.delete(:phone_mobile)
    row.delete(:phone_work)

    (attrs - [:phone_private, :phone_mobile, :phone_work]).each do |attr|
      expect(data.send(attr)).to eq row[attr]
    end
    expect(data.phone_private).to be_nil
    expect(data.phone_mobile).to be_nil
    expect(data.phone_work).to be_nil
  end
end
