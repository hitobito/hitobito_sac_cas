# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

CustomContent.seed_once(:key,
{ key: Event::ParticipationMailer::CONTENT_REJECTED_PARTICIPATION, # 'event_participation_rejected`
  placeholders_required: 'participant-name',
  placeholders_optional: 'event-name, application-url, event-details' },
  { key: Qualifications::ExpirationMailer::REMINDER_TODAY },
  { key: Qualifications::ExpirationMailer::REMINDER_NEXT_YEAR },
  { key: Qualifications::ExpirationMailer::REMINDER_YEAR_AFTER_NEXT_YEAR },
  { key: Memberships::LeaveZusatzsektionMailer::CONFIRMATION, placeholders_required: 'person-name, sektion-name, terminate-on' },
  { key: Memberships::TerminateSacMembershipMailer::CONFIRMATION, placeholders_required: 'person-name, sektion-name, terminate-on' },
  { key: Memberships::SwitchStammsektionMailer::CONFIRMATION, placeholders_required: 'person-name, group-name, switch-date' }
)

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
    label: "Evento: E-mail della notifica della rifiuto" },
  { custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_TODAY).id,
    locale: 'de',
    label: 'Qualifikation: Erinnerungsmail morgen',
    subject: 'Erinnerung TL-Anerkennung',
    body: 'Liebe(r) Tourenleiter(in), deine TL-Anerkennung ist ab morgen sistiert. ' \
      'Du darfst keine Touren für deine Sektion mehr leiten. ' \
      'Bitte absolviere die nötigen Fortbildungstage, um wieder als aktive(r) Leiter(in) registriert sein zu können.' },
  { custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_NEXT_YEAR).id,
    locale: 'de',
    label: 'Qualifikation: Erinnerungsmail in 1 Jahr',
    subject: 'Erinnerung TL-Anerkennung',
    body: 'Liebe(r) Tourenleiter(in), per Ende Jahr läuft deine TL-Anerkennung ab. ' \
      'Du darfst keine Touren für deine Sektion mehr leiten. ' \
      'Absolviere bitte die nötigen Fortbildungstage, damit du per Ende Jahr nicht sistiert wirst.' },
  { custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_YEAR_AFTER_NEXT_YEAR).id,
    locale: 'de',
    label: 'Qualifikation: Erinnerungsmail in 2 Jahren',
    subject: 'Erinnerung TL-Anerkennung',
    body: 'Liebe(r) Tourenleiter(in), in 2 Jahren läuft deine TL-Anerkennung ab. ' \
      'Plane rechtzeitig deine Fortbildungskurse in Absprache mit deinem(r) Tourenchef(in).' } ,
  { custom_content_id: CustomContent.get(Memberships::LeaveZusatzsektionMailer::CONFIRMATION).id,
    locale: 'de',
    label: 'Mitgliedschaften: Bestätigung Austritt Zusatzsektion',
    subject: 'Bestätigung Austritt Zusatzsektion',
    body: 'Hallo {person-name},<br/><br/>' \
    'Der Austritt aus {sektion-name} wurde per {terminate-on} vorgenommen.'
  },
  { custom_content_id: CustomContent.get(Memberships::TerminateSacMembershipMailer::CONFIRMATION).id,
    locale: 'de',
    label: 'Bestätigung SAC Austritt',
    subject: 'Der SAC Austritt wurde per {terminate-on} vorgenommen',
    body: 'Hallo {person-name},<br/><br/>' \
    'Der SAC Austritt wurde per {terminate-on} vorgenommen.'
  },
 { custom_content_id: CustomContent.get(Memberships::SwitchStammsektionMailer::CONFIRMATION).id,
    locale: 'de',
    label: 'Mitgliedschaften: Bestätigung Sektionswechsel',
    subject: 'Bestätigung Sektionswechsel',
    body: 'Hallo {person-name}<br/><br/>,' \
    'Der Sektionswechsel zu {group-name} wurde per {switch-date} vorgenommen.'
  }
)
