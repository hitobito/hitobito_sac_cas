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
  class Nav5HutsImporter
    include LogCounts

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
      SacImports::Huts::SacCasPrivathuetteRow,
      SacImports::Huts::SacCasClubhuetteRow,
      SacImports::Huts::SektionshuetteRow,
      SacImports::Huts::SektionsClubhuetteRow
    ]

    REPORT_HEADERS = [
      :navision_id,
      :name,
      :status,
      :message,
      :warning,
      :error
    ].freeze

    attr_reader :output, :csv_report

    def initialize(output: $stdout)
      @path = source_path
      raise "Hütten Beziehungen Export excel file not found" unless @path.exist?

      @output = output
      @csv_report = SacImports::CsvReport.new("nav5-huts", REPORT_HEADERS, output:)
    end

    def import!
      @csv_report.log("The file contains #{rows.size} rows.")
      progress = SacImports::Progress.new(rows.size * ROW_IMPORTERS.size, title: "NAV5 Huts")

      log_counts_delta(csv_report, Group) do
        import_sac_cas_hut_groups
        ROW_IMPORTERS.each do |importer_class|
          rows.each do |row|
            progress.step
            importer = importer_class.new(row, csv_report:, output:)
            importer.import! if importer.can_process?
          end
        end

        ignoring_archival do
          Group.update_all(lft: nil, rgt: nil)
          Group.rebuild!(false)
        end
      end
      csv_report.finalize
    end

    private

    def source_path
      CsvSource::SOURCE_DIR.children.find do |pathname|
        pathname.to_s =~ /H(ue|ü)tten_Beziehungen/
      end
    end

    def print_summary(model_class)
      model_class.where("type LIKE '%huette%'").group(:type).count.sort_by(&:second).each do |row|
        output.puts row
        csv_report.log(row)
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
      Group.root.children.find_or_create_by(type: Group::SacCasClubhuetten.sti_name)
      Group.root.children.find_or_create_by(type: Group::SacCasPrivathuetten.sti_name)
    end

    def ignoring_archival
      old_value = Group.archival_validation
      Group.archival_validation = false
      yield
      Group.archival_validation = old_value
    end
  end
end
