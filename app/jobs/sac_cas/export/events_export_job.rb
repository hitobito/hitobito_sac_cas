# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Export::EventsExportJob
  def exporter
    return super unless tour_export?

    Export::Tabular::Events::Tours::List
  end

  private

  def tour_export?
    @filter_args[:type].to_s == Event::Tour.sti_name
  end
end
