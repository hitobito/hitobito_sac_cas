# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav2Base
    include LogCounts

    REPORT_HEADERS = [
      :navision_id,
      :person_name,
      :valid_from,
      :valid_until,
      :target_group,
      :target_role,
      :status,
      :message,
      :warning,
      :error
    ].freeze

    class_attribute :source_file, default: :NAV21
    class_attribute :report_name

    def initialize(output: $stdout)
      # PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @source_file = SacImports::CsvSource.new(source_file, source_dir: Pathname.new("/home/dilli/nextcloud-puzzle/projects/hitobito/hit-sac-cas"))
      @csv_report = SacImports::CsvReport.new(report_name, REPORT_HEADERS, output:)
    end

    def create
      @csv_report.log("The file contains #{@source_file.lines_count} rows.")

      run_import

      @csv_report.finalize
    end

    private

    def run_import
      raise "Implement in subclass"
    end
  end
end
