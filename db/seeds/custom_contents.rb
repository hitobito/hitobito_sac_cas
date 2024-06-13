# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

CustomContent.seed_once(:key,
{ key: Event::ParticipationMailer::CONTENT_REJECTED_PARTICIPATION, # 'event_participation_rejected`
  placeholders_required: 'participant-name',
  placeholders_optional: 'event-name, application-url, event-details' })

  participation_rejected_id =
  CustomContent.get(Event::ParticipationMailer::CONTENT_REJECTED_PARTICIPATION).id

  CustomContent::Translation.seed_once(:custom_content_id, :locale,
  { custom_content_id: participation_rejected_id,
    locale: 'de',
    label: 'Anlass: E-Mail Ablehnung',
    subject: 'Kursablehnung',
    body: "Hallo {participant-name}<br/><br/>" \
          "Sie wurden leider für den Kurs {event-name} abgelehnt.<br/><br/>" \
          "Siehe {application-url}<br/><br/>" \
          "Kursdetails:<br/>{event-details}<br/>" },

  { custom_content_id: participation_rejected_id,
    locale: 'fr',
    label: "Événement: E-Mail de refus" },

  { custom_content_id: participation_rejected_id,
    locale: 'en',
    label: 'Event: Rejection email' },

  { custom_content_id: participation_rejected_id,
    locale: 'it',
    label: "Evento: E-mail della notifica della rifiuto" }
  )
