# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class TotalRevenue
    def fetch(course_ids)
      ExternalInvoice
        .joins("INNER JOIN event_participations ON " \
             "event_participations.id = external_invoices.link_id")
        .where(external_invoices: {link_type: "Event::Participation"})
        .where.not(external_invoices: {state: "cancelled"})
        .where(event_participations: {event_id: course_ids, state: "attended"})
        .group("event_participations.event_id")
        .sum("external_invoices.total")
    end
  end
end
