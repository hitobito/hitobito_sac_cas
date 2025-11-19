# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics do
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }

  let(:xlsx) { described_class.new(group, range) }

  it "renders xlsx" do
    expect(xlsx).to receive(:add_row).with(["Aktive Mitglieder am 31.12.2024"], :title)
    expect(xlsx).to receive(:add_row).with(["Anzahl Total", nil, 4]).once
    expect(xlsx).to receive(:add_row).with(["  Davon"]).exactly(4).times
    expect(xlsx).to receive(:add_row).with(["  - Geschlecht", "m", 0])
    expect(xlsx).to receive(:add_row).with(["  - Geschlecht", "d", 3])
    expect(xlsx).to receive(:add_row).with(["Eintritte 01.01.2024 - 31.12.2024"], :title)
    expect(xlsx).to receive(:add_row).with(["  - Eintrittsgrund", "Keine Angabe", 0])
    expect(xlsx).to receive(:add_row).with(["  - Eintrittsgrund", "Weil der SAC eine gute Sache ist.", 0])
    expect(xlsx).to receive(:add_row).with(["Austritte 01.01.2024 - 31.12.2024"], :title)
    expect(xlsx).to receive(:add_row).with(["  - Austrittsgrund", "Umgezogen", 0])
    expect(xlsx).to receive(:add_row).at_least(10).times

    xlsx.generate
    # File.binwrite("test_mitglieder_statistics.xlsx", xlsx.generate)
  end
end
