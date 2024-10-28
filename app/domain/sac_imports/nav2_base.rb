# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav2Base
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
      PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @source_file = SacImports::CsvSource.new(source_file)
      @csv_report = SacImports::CsvReport.new(report_name, REPORT_HEADERS)
      @failed_person_ids = []
    end

    def create
      run_import

      @csv_report.finalize(output: @output)
    end

    private

    def run_import
      raise "Implement in subclass"
    end

    def count_roles = Role.unscoped.count

    def count_roles_by_type = Role.unscoped.group(:type).count

    def count_groups = Group.unscoped.count

    def count_groups_by_type = Group.unscoped.group(:type).count

    def calculate_delta_by_type(after_count_by_type, before_count_by_type)
      after_count_by_type
        .merge(before_count_by_type) { |_, after, before| after.to_i - before.to_i }
        .select { |_, count| count != 0 }
    end

    def log_count_change(type)
      before_count = send(:"count_#{type}")
      before_count_by_type = send(:"count_#{type}_by_type")
      yield
      delta_count = send(:"count_#{type}") - before_count
      after_count_by_type = send(:"count_#{type}_by_type")

      @csv_report.log("Count delta for all #{type}: #{delta_count}")

      delta_by_type = calculate_delta_by_type(after_count_by_type, before_count_by_type)
      delta_by_type.keys.sort.each do |type|
        @csv_report.log("Count delta for #{type}: #{delta_by_type[type]}")
      end
    end
  end
end
