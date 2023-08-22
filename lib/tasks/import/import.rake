# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require_relative '../../hitobito_sac_cas/import/sections_importer.rb'
require_relative '../../hitobito_sac_cas/import/huts_importer.rb'

namespace :import do
  desc 'Import sections from a navision export'
  task sections: [:environment] do
    sections_excel = Wagons.find('sac_cas').root.join('db/seeds/production/Sektion_Export_20230629.xlsx')
    Import::SectionsImporter.new(sections_excel).import!
  end

  desc 'Import huts from a navision export'
  task huts: [:environment] do
    #huts_excel = Wagons.find('sac_cas').root.join('db/seeds/production/Hütten_Export_20230704.xlsx')
    hut_relations_excel = Wagons.find('sac_cas').root.join('db/seeds/production/Hütten_Beziehungen_Export_20230704.xlsx')
    Import::HutsImporter.new(hut_relations_excel).import!
  end
end
