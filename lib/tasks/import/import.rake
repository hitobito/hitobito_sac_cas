# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require_relative '../../hitobito_sac_cas/import/sections_importer.rb'
require_relative '../../hitobito_sac_cas/import/huts_importer.rb'
require_relative '../../hitobito_sac_cas/import/people/bluemlisalp_importer.rb'


# rubocop:disable Metrics/LineLength
namespace :import do
  desc 'Import sections from a navision export'
  task sections: [:environment] do
    import_file_path = 'db/seeds/production/Sektion_Export_20230629.xlsx'
    sections_excel = Wagons.find('sac_cas').root.join(import_file_path)
    Import::SectionsImporter.new(sections_excel).import!
  end

  desc 'Import huts from a navision export'
  task huts: [:environment] do
    #huts_excel = Wagons.find('sac_cas').
    #root.join('db/seeds/production/Hütten_Export_20230704.xlsx')

    import_file_path = 'db/seeds/production/Hütten_Beziehungen_Export_20230704.xlsx'
    hut_relations_excel = Wagons.find('sac_cas').root.join(import_file_path)
    Import::HutsImporter.new(hut_relations_excel).import!
  end

  desc 'Import people for bluemlisalp section from a navision export'
  task bluemlisalp_people: [:environment] do
    bluemlisalp_people_excel = Wagons.find('sac_cas').root.join('db/seeds/production/Mitglieder_SAC_Blüemlisalp_Export_20230629.xlsx')
    Import::People::BluemlisalpImporter.new(bluemlisalp_people_excel).import!
  end
end
# rubocop:enable Metrics/LineLength
