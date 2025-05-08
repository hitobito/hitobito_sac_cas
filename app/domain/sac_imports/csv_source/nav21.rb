# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # Event::Participation
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav21 = Data.define(
    :person_id,
    :event_number,
    :state,
    :additional_information,
    :qualified,
    :canceled_at,
    :cancel_statement,
    :subsidy,
    :actual_days,
    :price,
    :price_category,
    :role_type,
    :role_label,
    :role_self_employed
  )
end
