# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class ImporterBase
    class_attribute :rows_filter

    def create
      # @data.each { process_row(_1) }
      @csv_report.log("The file contains #{@data.size} rows.")
      progress = SacImports::Progress.new(@data.size, title: title)

      Parallel.map(@data, in_threads: nr_of_threads) do |row|
        progress.step
        process_row(row)
      end
    end

    private

    def process_row(row)
      return unless dates_valid?(row)
      person = fetch_person(row)
      return unless person

      yield(person)
    end

    def title = self.class.name.demodulize.gsub(/Importer$/, "")

    def navision_id(row)
      Integer(row.navision_id) if row.navision_id.present?
    end

    def nr_of_threads
      Rails.env.test? ? 1 : 6
    end

    def fetch_person(row)
      person = Person.find_by(id: row.navision_id)
      return person unless person.nil?

      report_person_not_found(row)
      nil
    end

    def dates_valid?(row)
      valid_until = Date.parse(row.valid_until) if row.valid_from.present?
      valid_from = Date.parse(row.valid_from) if row.valid_from.present?
      return true if valid_from.blank? || valid_until.blank? || valid_from < valid_until

      report(row, nil, error: "valid_from (GültigAb) cannot be before valid_until (GültigBis)")
      false
    end

    def terminated?(row)
      return false if row.valid_until.blank?

      Date.current.end_of_year > Date.parse(row.valid_until)
    end

    def save_role!(role, row)
      begin
        role.save!(context: :import)
      rescue ActiveRecord::RecordInvalid
        report(row, nil, error: "#{role.class}: " + role.errors.full_messages.join(", "))
        return nil
      end
      role
    end

    def report_person_not_found(row)
      report(row, nil, error: "Person not found in hitobito")
    end

    def report(row, person, message: nil, warning: nil, error: nil)
      message_prefix = "#{row.navision_id} (#{person})"
      symbol = error.present? ? "❌" : "✅"
      details = error || message || warning
      status = if error.present?
        "error"
      else
        warning.present? ? "warning" : "success"
      end

      @output.puts("#{message_prefix}: #{symbol} #{details}") if error.present?
      add_report_row(row, status, message: message, warning: warning, error: error)
    end

    def add_report_row(row, status, message: nil, warning: nil, error: nil)
      @csv_report.add_row({
        navision_id: row.navision_id,
        person_name: row.person_name,
        valid_from: row.valid_from,
        valid_until: row.valid_until,
        target_group: row.group_path,
        target_role: row.role,
        status: status,
        message: message,
        warning: warning,
        error: error
      })
    end

    def collect_csv_source_person_ids
      @data.map { |row| navision_id(row) }.uniq
    end
  end
end
