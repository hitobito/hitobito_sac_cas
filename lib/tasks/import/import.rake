# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# rubocop:disable Metrics/LineLength
namespace :import do
  desc 'Import sections from a navision export (tmp/xlsx/sektionen.xlsx)'
  task sektionen: [:environment] do
    import_file_path = 'tmp/xlsx/sektionen.xlsx'
    sektionen_excel = Rails.root.join(import_file_path)
    Import::SektionenImporter.new(sektionen_excel).import!
  end

  desc 'Import huts from a navision export'
  task huts: [:environment] do
    import_file_path = 'tmp/Hütten_Beziehungen_Export_20230704.xlsx'
    hut_relations_excel = Rails.root.join(import_file_path)
    Import::HutsImporter.new(hut_relations_excel).import!
  end

  desc 'Import people (Hauptsektion) for sektion from a navision export FILE=tmp/xlsx/sektions_mitglieder.xlsx'
  task sektions_mitglieder: [:environment] do
    Import::Sektion::MitgliederImporter.new(Pathname(ENV['FILE'].to_s), Person.find_by!(email: Settings.root_email)).import!
  end
end
# rubocop:enable Metrics/LineLength
