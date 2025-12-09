# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::AustritteExportJob do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:from) { Date.new(2015, 1, 1) }
  let(:to) { Date.new(2015, 12, 31) }
  let(:filename) { "Austritte" }
  let(:file) { job.send(:async_download_file) }

  subject(:job) { described_class.new(user.id, group.id, filename, from, to) }

  def create_role_plain(type, **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", attrs.reverse_merge(group: group))
  end

  def create_role(type = "Mitglied", **attrs)
    end_on = [attrs[:start_on].to_date, Date.current].max.end_of_year
    create_role_plain(type, **attrs.merge(end_on:)).tap do |role|
      if attrs[:end_on]
        terminate_role(role, **attrs)
      end
    end
  end

  def terminate_role(role, **attrs)
    Roles::Termination.new(role:, terminate_on: attrs[:end_on], validate_terminate_on: false).call
  end

  before do
    create_role(start_on: "1.1.2000", end_on: "10.9.2015")
    create_role(start_on: "1.1.2000", end_on: "31.12.2015")
    create_role(start_on: "1.1.2000", end_on: "31.12.2014") # out of scope
  end

  it "creates a XLSX-Export" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(3).times
      .and_call_original

    travel_to(Time.zone.local(2015, 10, 10)) do
      expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)
      expect(file.filename).to eq("Austritte.xlsx")
    end
  end
end
