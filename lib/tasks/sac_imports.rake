# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_imports do

  desc "Import all people from a navision export xlsx" \
         " (options: FILE=tmp/xlsx/personen.xlsx REIMPORT_ALL=true)"
  task '1_people': [:environment] do
    SacImports::PeopleImporter.new(
      Pathname(ENV["FILE"].to_s),
      skip_existing: !["1", "true"].include?(ENV["REIMPORT_ALL"].to_s.downcase)
    ).import!
  end

  desc "Import sections from a navision export (tmp/xlsx/sektionen.xlsx)"
  task '2_sektionen': [:environment] do
    import_file_path = "tmp/xlsx/sektionen.xlsx"
    sektionen_excel = Rails.root.join(import_file_path)
    SacImports::SektionenImporter.new(sektionen_excel).import!
  end

  desc "Import huts from a navision export"
  task '3_huts': [:environment] do
    import_file_path = "tmp/xlsx/huetten_beziehungen.xlsx"
    hut_relations_excel = Rails.root.join(import_file_path)
    SacImports::HutsImporter.new(hut_relations_excel).import!
  end

  desc "Import memberships from a navision export xlsx" \
         " (options: FILE=tmp/xlsx/mitglieder_aktive.xlsx REIMPORT_ALL=true)"
  task '4_memberships': [:environment] do
    SacImports::Sektion::MembershipsImporter.new(
      Pathname(ENV["FILE"].to_s),
      skip_existing: !["1", "true"].include?(ENV["REIMPORT_ALL"].to_s.downcase)
    ).import!
  end

  desc "Import additional memberships from a navision export xlsx" \
         " (options: FILE=tmp/xlsx/zusatzmitgliedschaften.xlsx REIMPORT_ALL=true)"
  task '5_additonal_memberships': [:environment] do
    SacImports::Sektion::AdditionalMembershipsImporter.new(
      Pathname(ENV["FILE"].to_s),
      skip_existing: !["1", "true"].include?(ENV["REIMPORT_ALL"].to_s.downcase)
    ).import!
  end

  desc "Analyse imported and calculated membership years and create report"
  task '6_membership_years_report': [:environment] do
    SacImports::MembershipYearsReport.new.create
  end
end
