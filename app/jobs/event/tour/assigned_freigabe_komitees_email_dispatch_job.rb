# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito__sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob < Event::Tour::EmailDispatchJob
  private

  def recipients
    freigabe_komitee_ids = Event::ApprovalCommissionResponsibility.where(sektion_id: tour.group_ids,
      target_group: tour.main_target_groups,
      discipline: tour.main_disciplines,
      subito: tour.subito).distinct.pluck(:freigabe_komitee_id)

    Person.joins(:roles).where(roles: {group_id: freigabe_komitee_ids})
  end
end
