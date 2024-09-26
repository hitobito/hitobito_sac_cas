# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_imports do
  def skip_existing? = ["1", "true"].exclude?(ENV["REIMPORT_ALL"].to_s.downcase)

  def default_files = {
    sektionen: "tmp/xlsx/sektionen.xlsx",
    huts: "tmp/xlsx/huetten_beziehungen.xlsx"
  }

  desc "Import people"
  task "1_people": [:environment] do
    SacImports::PeopleImporter.new.create
  end

  desc "Import sections from a navision export (tmp/xlsx/sektionen.xlsx)" \
         " (options: FILE=#{default_files[:sektionen]})"
  task "2_sektionen": [:environment] do
    SacImports::SektionenImporter.new(read_file(:sektionen)).import!
  end

  desc "Import huts from a navision export" \
         " (options: FILE=#{default_files[:huts]})"
  task "3_huts": [:environment] do
    SacImports::HutsImporter.new(read_file(:huts)).import!
  end

  desc "Import roles"
  task "4_roles": [:environment] do
    SacImports::Roles::Importer.new.create
  end

  desc "Import additional memberships from a navision export xlsx" \
         " (options: FILE=#{default_files[:additional_memberships]} REIMPORT_ALL=true)"
  task "5_additonal_memberships": [:environment] do
    SacImports::Sektion::AdditionalMembershipsImporter.new(
      read_file(:additional_memberships),
      skip_existing: !["1", "true"].include?(ENV["REIMPORT_ALL"].to_s.downcase)
    ).import!
  end

  desc "Analyse imported and calculated membership years and create report"
  task "6_membership_years_report": [:environment] do
    SacImports::MembershipYearsReport.new.create
  end

  desc "Import people from WSO2"
  task "7_wso2_people": [:environment] do
    SacImports::Wso2PeopleImporter.new.create
  end

  def read_file(kind)
    Pathname(ENV["FILE"].presence || Rails.root.join(default_files.fetch(kind)))
  end
end
