# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::MailingListPeopleEmailDispatchJob < Event::Tour::EmailDispatchJob
  private

  def recipients
    mailing_list_key = tour.subito? ?
      SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY :
      SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY

    MailingList.find_by(internal_key: mailing_list_key)&.people || Person.none
  end
end
