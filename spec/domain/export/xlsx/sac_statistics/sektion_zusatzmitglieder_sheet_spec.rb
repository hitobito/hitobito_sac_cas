# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::SacStatistics::SektionZusatzmitgliederSheet do
  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }
  let(:xlsx) { RowCollector.new }
  let(:sheet) { described_class.new(xlsx, range) }

  def create_role(type, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", group:, **attrs)
  end

  def numbers(sektion)
    xlsx.rows.find { |row| row.first == groups(sektion).id }&.slice(1..)
  end

  it "renders xlsx" do
    sheet.generate
    expect(xlsx.rows.first).to eq(
      ["Id", "Name", "Typ", "Total", "Einzel", "Jugend", "Familie", "FreiFam", "FreiKind", :title]
    )
    expect(xlsx.rows.size).to eq(5)

    expect(xlsx.rows.map(&:second))
      .to eq(["Name", "SAC Blüemlisalp", "SAC Blüemlisalp Ausserberg", "SAC Matterhorn", nil])

    expect(numbers(:bluemlisalp_ortsgruppe_ausserberg))
      .to eq(["SAC Blüemlisalp Ausserberg", "Ortsgruppe", 0, 0, 0, 0, 0, 0])
    expect(numbers(:bluemlisalp)).to eq(["SAC Blüemlisalp", "Sektion", 0, 0, 0, 0, 0, 0])
    expect(numbers(:matterhorn)).to eq(["SAC Matterhorn", "Sektion", 4, 1, 0, 1, 1, 1])

    expect(xlsx.rows.last).to eq(
      ["Total", nil, nil, 4, 1, 0, 1, 1, 1]
    )
  end
end
