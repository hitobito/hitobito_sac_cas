# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")
require_relative "huts/hut_commission_row"
require_relative "huts/huts_row"
require_relative "huts/hut_row"
require_relative "huts/hut_chief_row"
require_relative "huts/hut_warden_row"
require_relative "huts/hut_warden_partner_row"
require_relative "huts/hut_chairman_row"
require_relative "huts/key_deposit_row"

module SacImports
  class HutsImporter
    HEADERS = {
      contact_navision_id: "Kontaktnr.",
      contact_name: "Kontaktname",
      hut_category: "Hüttenkategorie",
      verteilercode: "Verteilercode",
      related_navision_id: "Beziehung",
      related_last_name: "Name",
      related_first_name: "Vorname",
      created_at: "Gültig von"
    }

    IMPORTERS = [
      SacImports::Huts::HutCommissionRow,
      SacImports::Huts::HutsRow,
      SacImports::Huts::HutRow,
      SacImports::Huts::HutChiefRow,
      SacImports::Huts::HutWardenRow,
      SacImports::Huts::HutWardenPartnerRow,
      SacImports::Huts::HutChairmanRow,
      SacImports::Huts::KeyDepositRow
    ]

    def initialize(path)
      raise "Hütten Beziehungen Export excel file not found" unless path.exist?
      @path = path
    end

    def import!
      without_query_logging do
        IMPORTERS.each do |importer|
          Import::XlsxReader.read(@path, "Beziehungen_Data", headers: HEADERS) do |row|
            importer.new(row).import! if importer.can_process?(row)
          end
        end
        ignoring_archival do
          Group.update_all(lft: nil, rgt: nil)
          Group.rebuild!(false)
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

    def ignoring_archival
      old_value = Group.archival_validation
      Group.archival_validation = false
      yield
      Group.archival_validation = old_value
    end
  end
end