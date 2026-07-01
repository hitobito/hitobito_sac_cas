# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::AlpsRecipientsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:reference_date, :new_entries_from]

  def initialize(user_id, filename, reference_date, new_entries_from, **)
    @reference_date = reference_date
    @new_entries_from = new_entries_from
    super(:xlsx, user_id, filename: filename, **)
  end

  def data # rubocop:disable Metrics/MethodLength
    entries = []
    begin
      # use single << calls so that already created temporary files get closed
      # even if a subsequent xlsx generations fails
      entries << ["AlpenD.xlsx", generate_alpen(:de)]
      entries << ["AlpenF.xlsx", generate_alpen(:fr)]
      entries << ["AlpenI.xlsx", generate_alpen(:it)]
      entries << ["AlpenDeutschland.xlsx", generate_alpen_germany]
      entries << ["Alpen.xlsx", generate_alpen_all]
      if @new_entries_from
        entries << ["DE_NeumitgliederHuettenkarte.xlsx", generate_new_entries(:de)]
        entries << ["FR_NeumitgliederHuettenkarte.xlsx", generate_new_entries(:fr)]
        entries << ["IT_NeumitgliederHuettenkarte.xlsx", generate_new_entries(:it)]
      end

      generate_zip(entries)
    ensure
      entries.each { |_, tmpfile| tmpfile.close! }
    end
  end

  private

  def generate_zip(entries)
    Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, tmpfile|
        zip.put_next_entry(name)
        zip.write(File.binread(tmpfile.path))
      end
    end.string
  end

  def generate_alpen(lang)
    write_temp_xlsx(recipients_scope.regular(lang))
  end

  def generate_alpen_all
    write_temp_xlsx(recipients_scope.all, full: true)
  end

  def generate_alpen_germany
    write_temp_xlsx(recipients_scope.germany)
  end

  def generate_new_entries(lang)
    write_temp_xlsx(recipients_scope.new_entries(lang))
  end

  def write_temp_xlsx(scope, full: false)
    Tempfile.new(["alps_recipients", ".xlsx"]).tap do |tmpfile|
      tmpfile.binmode
      tmpfile.write(generate_xlsx(scope, full:))
      tmpfile.flush
    end
  end

  def generate_xlsx(scope, full: false)
    Export::Tabular::People::AlpsRecipients.xlsx(
      scope,
      @reference_date,
      abonnent_group_langs,
      full:
    )
  end

  def abonnent_group_langs
    @abonnent_group_langs ||= recipients_scope.abonnent_group_ids.invert.transform_values(&:to_s)
  end

  def recipients_scope
    @people_scope ||=
      Export::Tabular::People::AlpsRecipientsScope.new(@reference_date, @new_entries_from)
  end
end
