# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::BeitragskategorieWechselExportJob do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:from) { Date.new(2015, 1, 1) }
  let(:to) { Date.new(2015, 12, 31) }
  let(:filename) { "Wechsel_Beitragskategorie" }
  let(:file) { job.send(:async_download_file) }

  subject(:job) { described_class.new(user.id, group.id, filename, from, to) }

  def create_role(beitragskategorie, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::Mitglied", group:, beitragskategorie:, **attrs)
  end

  before do
    create_role("youth", person: people(:mitglied), start_on: "1.1.2000", end_on: "31.12.2014")
    create_role("adult", person: people(:familienmitglied), start_on: "1.1.2000", end_on: "31.12.2014")
    create_role("adult", person: people(:familienmitglied2), start_on: "1.1.2000", end_on: "31.12.2014")
  end

  it "creates a XLSX-Export" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(4).times
      .and_call_original

    expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)
    expect(file.filename).to eq("Wechsel_Beitragskategorie.xlsx")
  end
end
