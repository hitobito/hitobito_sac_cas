# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')
require_relative 'huts/hut_row.rb'
require_relative 'huts/hut_chief_row.rb'
require_relative 'huts/hut_warden_row.rb'
require_relative 'huts/hut_warden_partner_row.rb'
require_relative 'huts/unsupported_row.rb'

module Import
  class HutsImporter

    HEADERS = {
      contact_navision_id: 'Kontaktnr.',
      contact_name: 'Kontaktname',
      verteilercode: 'Verteilercode',
      related_navision_id: 'Beziehung',
      related_last_name: 'Name',
      related_first_name: 'Vorname',
      created_at: 'Gültig von',
    }

    ROW_IMPORTERS = [
      Import::Huts::HutRow,
      Import::Huts::HutChiefRow,
      Import::Huts::HutWardenRow,
      Import::Huts::HutWardenPartnerRow,

      Import::Huts::UnsupportedRow # must be last
    ]

    def initialize(path)
      raise 'Hütten Beziehungen Export excel file not found' unless path.exist?
      @path = path
    end

    def import!
      without_query_logging do
        Import::XlsxReader.read(@path, 'Beziehungen_Data', headers: HEADERS) do |row|
          importer_class = row_importer_for(row)
          puts "Importing row using #{importer_class.name}"
          importer_class.new(row).import!
        end
      end
    end

    private

    def without_query_logging
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      yield
      ActiveRecord::Base.logger = old_logger
    end

    def row_importer_for(row)
      ROW_IMPORTERS.find { |importer_class| importer_class.can_process?(row) }
    end

  end
end
