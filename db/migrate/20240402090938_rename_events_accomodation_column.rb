# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class RenameEventsAccomodationColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column(:event_kinds, :accomodation, :accommodation)
    rename_column(:events, :accomodation, :accommodation)
    Event.reset_column_information
    Event::Course.reset_column_information
  end
end
