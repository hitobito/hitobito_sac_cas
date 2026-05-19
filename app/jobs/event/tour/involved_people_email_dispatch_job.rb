# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::InvolvedPeopleEmailDispatchJob < Event::Tour::EmailDispatchJob
  private

  def recipients
    Person.where(id: [tour.contact_id, tour.updater_id].compact.uniq)
  end
end
