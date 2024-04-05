# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacCas::Export::MitgliederExportJob < Export::ExportBaseJob
  ENCODING = 'ISO-8859-1'

  self.parameters = PARAMETERS + [:group_id]

  def initialize(user_id, group_id, **options)
    @group_id = group_id
    filename = "Adressen_#{group.navision_id_padded}"
    super(:csv, user_id, filename: filename, **options)
  end

  def data
    tabular = Export::Tabular::People::SacMitglieder.new(group)
    [
      Export::Csv::Generator.new(tabular,
                                 encoding: ENCODING,
                                 utf8_bom: false,
                                 col_sep: '$').call,
      summary_line(tabular)
    ].join
  end

  private

  def group
    @group ||= Group.find(@group_id)
  end

  def summary_line(tabular)
    navision_id = group.navision_id_padded
    count = tabular.list.size
    date = I18n.l(Time.zone.now.to_date, format: '%d.%m.%Y')
    time = Time.zone.now.strftime('%H:%M')
    [
      '* * * Dateiende * * *',
      navision_id,
      "Anzahl Datensätze: #{count}",
      date,
      time
    ].join(' / ').encode(ENCODING)
  end
end
