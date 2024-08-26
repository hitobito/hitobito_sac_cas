# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")
require_relative "huts/hut_commission_row"
require_relative "huts/huts_row"
require_relative "huts/hut_row"

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

    ROW_IMPORTERS = [
      SacImports::Huts::HutCommissionRow,
      SacImports::Huts::HutsRow,
      SacImports::Huts::HutRow,
      SacImports::Huts::SacCasPrivathuetteRow,
      SacImports::Huts::SacCasClubhuetteRow,
      SacImports::Huts::SektionshuetteRow,
      SacImports::Huts::SektionsClubhuetteRow
    ]

    def initialize(path)
      raise "Hütten Beziehungen Export excel file not found" unless path.exist?
      @path = path
    end

    def import!
      without_query_logging do
        import_sac_cas_hut_groups
        ROW_IMPORTERS.each do |importer_class|
          rows.each do |row|
            importer = importer_class.new(row)
            importer.import! if importer.can_process?
          end
        end

        ignoring_archival do
          Group.update_all(lft: nil, rgt: nil)
          Group.rebuild!(false)
        end
      end
      print_summary(Group)
      print_summary(Role)
    end

    private

    def print_summary(model_class)
      model_class.where('type LIKE "%huette%"').group(:type).count.sort_by(&:second).each do |row|
        p row
      end
    end

    def rows
      @rows ||= [].tap do |rows|
        Import::XlsxReader.read(@path, "Beziehungen_Data", headers: HEADERS) do |row|
          rows << row
        end
      end
    end

    def import_sac_cas_hut_groups
      Group::SacCas.first.children.find_or_create_by(type: Group::SacCasClubhuetten)
      Group::SacCas.first.children.find_or_create_by(type: Group::SacCasPrivathuetten)
    end

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
