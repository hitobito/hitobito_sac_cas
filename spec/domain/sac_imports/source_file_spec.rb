# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::SourceFile do
  let(:source_file) { described_class.new(@source_name) }

  it "throws error if unavailable source file referenced" do
    @source_name = :NAV42
    expect do
      source_file.path
    end.to raise_error("Invalid source name: NAV42\navailable sources: #{SacImports::SourceFile::AVAILABLE_SOURCES.map(&:to_s).join(', ')}")

  end

  it "throws error if requested source file does not exist" do
    @source_name = :NAV2
    expect do
      source_file.path
    end.to raise_error("No source file NAV2_*.xlsx found in RAILS_CORE_ROOT/tmp/xlsx/.")
  end

  it "returns existing source file" do
    @source_name = :NAV1
    expect(Dir)
      .to receive(:glob)
      .with("#{Rails.root.join("tmp", "xlsx")}/NAV1_*.xlsx")
      .and_return(["/usr/src/app/hitobito/tmp/xlsx/NAV1_kontakte_NAV-20240722.xlsx"])
    expect(source_file.path.to_s).to eq('/usr/src/app/hitobito/tmp/xlsx/NAV1_kontakte_NAV-20240722.xlsx')
  end
end
