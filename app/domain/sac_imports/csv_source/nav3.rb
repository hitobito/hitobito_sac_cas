# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav3 = Data.define(
    :navision_id, # "Kontaktnummer",
    :active, # "Ist_aktiv",
    :main_group, # "Hauptgruppe",
    :start_at, # "Gültig von",
    :finish_at, # "Gültig bis"
    :suspended_at, # "Sistiert ab",
    :reactivatable_until, # "Reaktivierbar bis",
    :qualification_kind # "Qualifikation",
  )
end
