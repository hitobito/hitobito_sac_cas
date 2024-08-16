# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

CustomContent.seed_once(:key,
  {key: Event::ParticipationMailer::CONTENT_REJECTED_PARTICIPATION,
   placeholders_required: "participant-name",
   placeholders_optional: "event-name, application-url, event-details"},
  {key: Event::ParticipationMailer::CONTENT_SUMMON,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, application-url, person-url, event-link, book-discount-code"},
  {key: Event::ApplicationConfirmationMailer::APPLIED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, missing-information"},
  {key: Event::ApplicationConfirmationMailer::UNCONFIRMED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, missing-information"},
  {key: Event::ApplicationConfirmationMailer::ASSIGNED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, missing-information"},
  {key: Event::LeaderReminderMailer::REMINDER_NEXT_WEEK,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link"},
  {key: Event::LeaderReminderMailer::REMINDER_8_WEEKS,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, six-weeks-before-start"},
  {key: Event::PublishedMailer::NOTICE,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, six-weeks-before-start, application-opening-at"},
  {key: Event::ApplicationPausedMailer::NOTICE,
   placeholders_required: "event-name",
   placeholders_optional: "event-number, event-link, event-details"},
  {key: Qualifications::ExpirationMailer::REMINDER_TODAY},
  {key: Qualifications::ExpirationMailer::REMINDER_NEXT_YEAR},
  {key: Qualifications::ExpirationMailer::REMINDER_YEAR_AFTER_NEXT_YEAR},
  {key: Memberships::LeaveZusatzsektionMailer::CONFIRMATION,
   placeholders_required: "person-name, sektion-name, terminate-on"},
  {key: Memberships::TerminateSacMembershipMailer::CONFIRMATION,
   placeholders_required: "person-name, sektion-name, terminate-on"},
  {key: Memberships::SwitchStammsektionMailer::CONFIRMATION,
   placeholders_required: "person-name, group-name"})

participation_rejected_id = CustomContent.get(Event::ParticipationMailer::CONTENT_REJECTED_PARTICIPATION).id
summon_id = CustomContent.get(Event::ParticipationMailer::CONTENT_SUMMON).id
leader_reminder_next_week_id = CustomContent.get(Event::LeaderReminderMailer::REMINDER_NEXT_WEEK).id
leader_reminder_8_weeks_id = CustomContent.get(Event::LeaderReminderMailer::REMINDER_8_WEEKS).id

CustomContent::Translation.seed_once(:custom_content_id, :locale,
  {custom_content_id: participation_rejected_id,
   locale: "de",
   label: "Anlass: E-Mail Ablehnung",
   subject: "Kursablehnung",
   body: "Hallo {participant-name}<br><br>" \
    "Sie wurden leider für den Kurs {event-name} abgelehnt.<br><br>" \
    "Siehe {application-url}<br><br>" \
    "Kursdetails:<br>{event-details}<br>"},
  {custom_content_id: participation_rejected_id,
   locale: "fr",
   label: "Événement: E-Mail de refus"},
  {custom_content_id: participation_rejected_id,
   locale: "en",
   label: "Event: Rejection email"},
  {custom_content_id: participation_rejected_id,
   locale: "it",
   label: "Evento: E-mail della notifica della rifiuto"},
  {custom_content_id: summon_id,
   locale: "de",
   label: "Kurs: E-Mail Aufgebot",
   subject: "Kurs: E-Mail Aufgebot",
   body: "Hallo {recipient-name},<br><br>" \
     "Sie wurden für den Kurs {event-name} (Nummer: {event-number}) aufgeboten.<br><br>" \
     "Kursdetails:<br><br>{event-details}<br><br>" \
     "Weitere Informationen:<br>" \
     "Anmeldung: {application-url}<br>" \
     "Person: {person-url}<br>" \
     "Event-Link: {event-link}<br>" \
     "Book-Discount-Code: {book-discount-code}"},
  {custom_content_id: summon_id,
   locale: "fr",
   label: "Événement: E-mail de convocation",
   subject: "Convocation au cours",
   body: "Bonjour {recipient-name},<br><br>" \
     "Vous avez été convoqué(e) pour le cours {event-name} (Numéro: {event-number}).<br><br>" \
     "Détails du cours:<br><br>{event-details}<br><br>" \
     "Informations supplémentaires:<br>" \
     "Inscription: {application-url}<br>" \
     "Personne: {person-url}<br>" \
     "Lien de l'événement: {event-link}<br>" \
     "Code de réduction pour le livre: {book-discount-code}"},
  {custom_content_id: CustomContent.get(Event::ApplicationConfirmationMailer::APPLIED).id,
   locale: "de",
   label: "Kurs: E-Mail Unbestätigte Warteliste",
   subject: "Auf Warteliste gesetzt",
   body: "Hallo {recipient-name},<br><br>" \
     "Du wurdest für den Kurs {event-name} (Nummer: {event-number}) auf die unbestätigte Warteliste gesetzt. " \
     "Anmeldeschluss ist der {application-closing-at}.<br><br>" \
     "Anmeldung: {application-url}<br>" \
     "Person: {person-url}<br>" \
     "Event-Link: {event-link}<br>" \
     "Kursdetails:<br><br>{event-details}<br><br>{missing-information}"},
  {custom_content_id: CustomContent.get(Event::ApplicationConfirmationMailer::UNCONFIRMED).id,
   locale: "de",
   label: "Kurs: E-Mail Unbestätigte Kursanmeldung",
   subject: "Unbestätigte Kursanmeldung",
   body: "Hallo {recipient-name},<br><br>" \
     "Du wurdest für den Kurs {event-name} (Nummer: {event-number}) auf die unbestätigte Kursanmeldung gesetzt. " \
     "Anmeldeschluss ist der {application-closing-at}.<br><br>" \
     "Anmeldung: {application-url}<br>" \
     "Person: {person-url}<br>" \
     "Event-Link: {event-link}<br>" \
     "Kursdetails:<br><br>{event-details}<br><br>{missing-information}"},
  {custom_content_id: CustomContent.get(Event::ApplicationConfirmationMailer::ASSIGNED).id,
   locale: "de",
   label: "Kurs: E-Mail Bestätigte Kursanmeldung",
   subject: "Kursanmeldung bestätigt",
   body: "Hallo {recipient-name},<br><br>" \
     "Deine Anmeldung für den Kurs {event-name} (Nummer: {event-number}) wurde bestätigt. " \
     "Anmeldeschluss ist der {application-closing-at}.<br><br>" \
     "Anmeldung: {application-url}<br>" \
     "Person: {person-url}<br>" \
     "Event-Link: {event-link}<br>" \
     "Kursdetails:<br><br>{event-details}<br><br>{missing-information}"},
  {custom_content_id: leader_reminder_next_week_id,
   locale: "de",
   label: "Kurs: E-Mail Kursvorbereitungen abschliessen",
   subject: "Erinnerung Kursstart",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) findet nächste Woche statt.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: leader_reminder_8_weeks_id,
   locale: "de",
   label: "Kurs: E-Mail Reminder Kursleitung",
   subject: "Erinnerung Kursstart",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) findet 6 Wochen nach dem {six-weeks-before-start} statt.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: leader_reminder_8_weeks_id,
   locale: "fr",
   label: "Kurs: E-Mail Reminder Kursleitung",
   subject: "Rappel de début de cours",
   body: "Bonjour {recipient-name},<br><br>" \
    "Le cours {event-name} (Nummer: {event-number}) aura lieu 6 semaines après le {six-weeks-before-start}.<br><br>" \
    "Lien de l'événement: {event-link}<br>" \
    "Détails du cours:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::PublishedMailer::NOTICE).id,
   locale: "de",
   label: "Kurs: E-Mail Kursveröffentlichung",
   subject: "Kursveröffentlichung",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}), der 6 Wochen nach dem {six-weeks-before-start} stattfinded, " \
    "wurde veröffentlicht. Anmeldebeginn ist der {application-opening-at}.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::ApplicationPausedMailer::NOTICE).id,
   locale: "de",
   label: "Kurs: E-Mail Anmeldung pausiert",
   subject: "Kursanmeldung pausiert",
   body: "Lieber Kursadmin,<br><br>" \
    "Die Anmeldung für den Kurs {event-name} (Nummer: {event-number}) wurde pausiert.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_TODAY).id,
   locale: "de",
   label: "Qualifikation: Erinnerungsmail morgen",
   subject: "Erinnerung TL-Anerkennung",
   body: "Liebe(r) Tourenleiter(in), deine TL-Anerkennung ist ab morgen sistiert. " \
    "Du darfst keine Touren für deine Sektion mehr leiten. " \
    "Bitte absolviere die nötigen Fortbildungstage, um wieder als aktive(r) Leiter(in) registriert sein zu können."},
  {custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_NEXT_YEAR).id,
   locale: "de",
   label: "Qualifikation: Erinnerungsmail in 1 Jahr",
   subject: "Erinnerung TL-Anerkennung",
   body: "Liebe(r) Tourenleiter(in), per Ende Jahr läuft deine TL-Anerkennung ab. " \
    "Du darfst keine Touren für deine Sektion mehr leiten. " \
    "Absolviere bitte die nötigen Fortbildungstage, damit du per Ende Jahr nicht sistiert wirst."},
  {custom_content_id: CustomContent.get(Qualifications::ExpirationMailer::REMINDER_YEAR_AFTER_NEXT_YEAR).id,
   locale: "de",
   label: "Qualifikation: Erinnerungsmail in 2 Jahren",
   subject: "Erinnerung TL-Anerkennung",
   body: "Liebe(r) Tourenleiter(in), in 2 Jahren läuft deine TL-Anerkennung ab. " \
    "Plane rechtzeitig deine Fortbildungskurse in Absprache mit deinem(r) Tourenchef(in)."},
  {custom_content_id: CustomContent.get(Memberships::LeaveZusatzsektionMailer::CONFIRMATION).id,
   locale: "de",
   label: "Mitgliedschaften: Bestätigung Austritt Zusatzsektion",
   subject: "Bestätigung Austritt Zusatzsektion",
   body: "Hallo {person-name},<br><br>" \
    "Der Austritt aus {sektion-name} wurde per {terminate-on} vorgenommen."},
  {custom_content_id: CustomContent.get(Memberships::TerminateSacMembershipMailer::CONFIRMATION).id,
   locale: "de",
   label: "Bestätigung SAC Austritt",
   subject: "Der SAC Austritt wurde per {terminate-on} vorgenommen",
   body: "Hallo {person-name},<br><br>" \
    "Der SAC Austritt wurde per {terminate-on} vorgenommen."},
  {custom_content_id: CustomContent.get(Memberships::SwitchStammsektionMailer::CONFIRMATION).id,
   locale: "de",
   label: "Mitgliedschaften: Bestätigung Sektionswechsel",
   subject: "Bestätigung Sektionswechsel",
   body: "Hallo {person-name},<br><br>" \
     "Der Sektionswechsel zu {group-name} wurde vorgenommen."})
