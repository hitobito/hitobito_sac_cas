# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

CustomContent.seed(:key,
  {key: Event::ParticipationMailer::REJECT_APPLIED_PARTICIPATION,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, application-url, person-url, event-link"},
  {key: Event::ParticipationMailer::REJECT_REJECTED_PARTICIPATION,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, application-url, person-url, event-link"},
  {key: Event::ParticipationMailer::SUMMONED_PARTICIPATION,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, application-url, person-url, event-link, book-discount-code"},
  {key: Event::ApplicationConfirmationMailer::APPLIED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, participation-price, missing-information"},
  {key: Event::ApplicationConfirmationMailer::UNCONFIRMED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, participation-price, missing-information"},
  {key: Event::ApplicationConfirmationMailer::ASSIGNED,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, application-closing-at, person-url, participation-price, missing-information"},
  {key: Event::ParticipationCanceledMailer::CONFIRMATION,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url"},
  {key: Event::ParticipantReminderMailer::REMINDER,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url, missing-information"},
  {key: Event::LeaderReminderMailer::REMINDER_NEXT_WEEK,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link"},
  {key: Event::LeaderReminderMailer::REMINDER_8_WEEKS,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, six-weeks-before-start"},
  {key: Event::PublishedMailer::NOTICE,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, six-weeks-before-start, application-opening-at"},
  {key: Event::CanceledMailer::MINIMUM_PARTICIPANTS,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url"},
  {key: Event::CanceledMailer::NO_LEADER,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url"},
  {key: Event::CanceledMailer::WEATHER,
   placeholders_required: "event-name",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url"},
  {key: Event::ApplicationPausedMailer::NOTICE,
   placeholders_required: "event-name",
   placeholders_optional: "event-number, event-link, event-details"},
  {key: Event::ApplicationClosedMailer::NOTICE,
   placeholders_required: "event-name",
   placeholders_optional: "event-number, event-link, event-details"},
  {key: Event::SurveyMailer::SURVEY,
   placeholders_required: "event-name, survey-link",
   placeholders_optional: "recipient-name, event-details, event-number, event-link, application-url, person-url"},
  {key: Qualifications::ExpirationMailer::REMINDER_TODAY},
  {key: Qualifications::ExpirationMailer::REMINDER_NEXT_YEAR},
  {key: Qualifications::ExpirationMailer::REMINDER_YEAR_AFTER_NEXT_YEAR},
  {key: Signup::AboMagazinMailer::CONFIRMATION,
   placeholders_required: "first-name, last-name, birthday, email, address-care-of, street-with-number, postbox, zip-code, town, country, abo-name, language, gender, costs, newsletter-subscribed, agb-link, data-protection-link"},
  {key: Signup::SektionMailer::CONFIRMATION,
   placeholders_required: "person-ids, first-name, last-name, birthday, email, phone-number, address-care-of, street-with-number, postbox, zip-code, town, country, section-name, membership-category, invoice-details",
   placeholders_optional: "profile-url, faq-url"},
  {key: Signup::SektionMailer::APPROVAL_PENDING_CONFIRMATION,
   placeholders_required: "person-ids, first-name, last-name, birthday, email, phone-number, address-care-of, street-with-number, postbox, zip-code, town, country, section-name, membership-category, invoice-details",
   placeholders_optional: "profile-url, faq-url"},
  {key: Memberships::JoinZusatzsektionMailer::CONFIRMATION,
   placeholders_required: "person-ids, first-name, last-name, birthday, email, phone-number, address-care-of, street-with-number, postbox, zip-code, town, country, section-name, membership-category, invoice-details",
   placeholders_optional: "profile-url, faq-url"},
  {key: Memberships::JoinZusatzsektionMailer::APPROVAL_PENDING_CONFIRMATION,
   placeholders_required: "person-ids, first-name, last-name, birthday, email, phone-number, address-care-of, street-with-number, postbox, zip-code, town, country, section-name, membership-category, invoice-details",
   placeholders_optional: "profile-url, faq-url"},
  {key: Invoices::SacMembershipsMailer::MEMBERSHIP_ACTIVATED,
   placeholders_required: "first-name",
   placeholders_optional: "profile-url, person-ids, last-name, birthday, email, phone-number, address-care-of, street-with-number, postbox, zip-code, town, country, section-name, membership-category,  invoice-details,  faq-url"},
  {key: Memberships::TerminateMembershipMailer::LEAVE_ZUSATZSEKTION,
   placeholders_required: "person-name, sektion-name, terminate-on"},
  {key: Memberships::TerminateMembershipMailer::TERMINATE_MEMBERSHIP,
   placeholders_required: "person-name, sektion-name, terminate-on"},
  {key: Memberships::SwitchStammsektionMailer::CONFIRMATION,
   placeholders_required: "person-name, group-name",
   placeholders_optional: "person-id"},
  {key: People::NeuanmeldungenMailer::APPROVED,
   placeholders_required: "first-name, sektion-name",
   placeholders_optional: "profile-url"},
  {key: People::NeuanmeldungenMailer::REJECTED,
   placeholders_required: "first-name, sektion-name"})

CustomContent::Translation.seed_once(:custom_content_id, :locale,
  {custom_content_id: CustomContent.get(Event::ParticipationMailer::REJECT_APPLIED_PARTICIPATION).id,
   locale: "de",
   label: "Kurs: E-Mail Keine Teilnahme 'Warteliste'",
   subject: "Kursablehnung",
   body: "Hallo {recipient-name},<br><br>" \
    "Du wurdest leider für den Kurs {event-name} (Nummer: {event-number}) abgelehnt.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::ParticipationMailer::REJECT_REJECTED_PARTICIPATION).id,
   locale: "de",
   label: "Kurs: E-Mail Keine Teilnahme 'Abgelehnt'",
   subject: "Kursablehnung",
   body: "Hallo {recipient-name},<br><br>" \
    "Du wurdest leider für den Kurs {event-name} (Nummer: {event-number}) abgelehnt.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::ParticipationMailer::SUMMONED_PARTICIPATION).id,
   locale: "de",
   label: "Kurs: E-Mail Aufgebot",
   subject: "Kurs: E-Mail Aufgebot",
   body: "Hallo {recipient-name},<br><br>" \
    "Du wurdest für den Kurs {event-name} (Nummer: {event-number}) aufgeboten.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Book-Discount-Code: {book-discount-code}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::ParticipationMailer::SUMMONED_PARTICIPATION).id,
   locale: "fr",
   label: "Événement: E-mail de convocation",
   subject: "Convocation au cours",
   body: "Bonjour {recipient-name},<br><br>" \
    "Vous avez été convoqué(e) pour le cours {event-name} (Numéro: {event-number}).<br><br>" \
    "Inscription: {application-url}<br>" \
    "Personne: {person-url}<br>" \
    "Lien de l'événement: {event-link}<br>" \
    "Code de réduction pour le livre: {book-discount-code}<br>" \
    "Détails du cours:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::ApplicationConfirmationMailer::APPLIED).id,
   locale: "de",
   label: "Kurs: E-Mail Unbestätigte Warteliste",
   subject: "Auf Warteliste gesetzt",
   body: "Hallo {recipient-name},<br><br>" \
    "Du wurdest für den Kurs {event-name} (Nummer: {event-number}) auf die unbestätigte Warteliste gesetzt. " \
    "Anmeldeschluss ist der {application-closing-at}.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Preis: {participation-price}<br>" \
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
    "Preis: {participation-price}<br>" \
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
    "Preis: {participation-price}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}<br><br>{missing-information}"},
  {custom_content_id: CustomContent.get(Event::ParticipationCanceledMailer::CONFIRMATION).id,
   locale: "de",
   label: "Kurs: E-Mail Abmeldung",
   subject: "Kursabmeldung bestätigt",
   body: "Hallo {recipient-name},<br><br>" \
    "Deine Abmeldung für den Kurs {event-name} (Nummer: {event-number}) wurde bestätigt. " \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}<br><br>{missing-information}"},
  {custom_content_id: CustomContent.get(Event::ParticipantReminderMailer::REMINDER).id,
   locale: "de",
   label: "Kurs: E-Mail Reminder TN Administrationsangaben",
   subject: "Fehlende Administrationsangaben",
   body: "Hallo {recipient-name},<br><br>" \
    "{missing-information}<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::LeaderReminderMailer::REMINDER_NEXT_WEEK).id,
   locale: "de",
   label: "Kurs: E-Mail Kursvorbereitungen abschliessen",
   subject: "Erinnerung Kursstart",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) findet nächste Woche statt.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::LeaderReminderMailer::REMINDER_8_WEEKS).id,
   locale: "de",
   label: "Kurs: E-Mail Reminder Kursleitung",
   subject: "Erinnerung Kursstart",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) findet 6 Wochen nach dem {six-weeks-before-start} statt.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
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
  {custom_content_id: CustomContent.get(Event::ApplicationClosedMailer::NOTICE).id,
   locale: "de",
   label: "Kurs: E-Mail Anmeldung abgeschlossen",
   subject: "Kursanmeldung abgeschlossen",
   body: "Lieber Kursadmin,<br><br>" \
    "Die Anmeldung für den Kurs {event-name} (Nummer: {event-number}) wurde abgeschlossen.<br><br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::CanceledMailer::MINIMUM_PARTICIPANTS).id,
   locale: "de",
   label: "Kurs: E-Mail Absage — Minimale Teilnehmerzahl nicht erreicht",
   subject: "Kurs abgesagt wegen zu wenig Anmeldungen",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) wurde leider abgesagt. " \
    "Grund dafür ist eine zu geringe Teilnehmerzahl.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::CanceledMailer::NO_LEADER).id,
   locale: "de",
   label: "Kurs: E-Mail Absage — Ausfall Kursleitung",
   subject: "Kurs abgesagt wegen Ausfall der Kursleitung",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) wurde leider abgesagt. " \
    "Grund dafür ist der Ausfall der Kursleitung.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::CanceledMailer::WEATHER).id,
   locale: "de",
   label: "Kurs: E-Mail Absage — Wetterrisiko",
   subject: "Kurs abgesagt wegen Wetterrisiko",
   body: "Hallo {recipient-name},<br><br>" \
    "Der Kurs {event-name} (Nummer: {event-number}) wurde leider abgesagt. " \
    "Grund dafür ist das Wetterrisiko.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
    "Event-Link: {event-link}<br>" \
    "Kursdetails:<br><br>{event-details}"},
  {custom_content_id: CustomContent.get(Event::SurveyMailer::SURVEY).id,
   locale: "de",
   label: "Kurs: E-Mail Umfrage",
   subject: "Kursumfrage",
   body: "Hallo {recipient-name},<br><br>" \
    "Wir hoffen, der Kurs {event-name} (Nummer: {event-number}) hat dir gut gefallen. Es würde uns sehr freuen, " \
    "wenn du dir einen Moment Zeit nehmen könntest, um an unserer Umfrage teilzunehmen: {survey-link}.<br><br>" \
    "Anmeldung: {application-url}<br>" \
    "Person: {person-url}<br>" \
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
  {custom_content_id: CustomContent.get(Signup::AboMagazinMailer::CONFIRMATION).id,
   locale: "de",
   label: "Abo Magazin: Bestellbestätigung",
   subject: "Bestellbestätigung - {abo-name}",
   body: <<~TEXT.strip.delete("\n")
     <strong>Abo Bestellung</strong><br>
     <br>
     |   |   |<br>
     | - | - |<br>
     | Gewünschte Sprache | {language} |<br>
     | Ab Ausgabe | Nächste Ausgabe nach Zahlungseingang |<br>
     | Preis | {costs} |<br>
     <br>
     <strong>Deine Angaben</strong><br>
     <br>
     |   |   |<br>
     | - | - |<br>
     | Geschlecht | {gender} |<br>
     | Vorname | {first-name} |<br>
     | Nachname | {last-name} |<br>
     | E-Mail | {email} |<br>
     | Adresszusatz | {address-care-of} |<br>
     | Strasse und Nr. | {street-with-number} |<br>
     | Postfach | {postbox} |<br>
     | PLZ | {zip-code} |<br>
     | Ort | {town} |<br>
     | Land | {country} |<br>
     | Geburtsdatum | {birthday} |<br>
     <br>
     <strong>Bestätigung</strong><br>
     <br>
     {newsletter-subscribed}<br>
     Ich habe die {agb-link} gelesen und stimme diesen zu.<br>
     Ich habe die {data-protection-link} gelesen und stimme diesen zu.<br>
     <br>
     Die Rechnung wird dir in einer separaten E-Mail zugestellt.
   TEXT
  },
  {custom_content_id: CustomContent.get(Signup::SektionMailer::CONFIRMATION).id,
   locale: "de",
   label: "SAC Eintritt: Bestellbestätigung ohne Freigabe",
   subject: "SAC Eintritt Bestellbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Wir freuen uns sehr, dass du dich für eine SAC-Mitgliedschaft entscheiden hast " \
    "und nun Teil des grössten Bergsportverbands der Schweiz bist.<br><br>" \
    "Folgende Angaben haben wir von dir erhalten. Sollten diese nicht korrekt sein, kannst du " \
    "sie im <a href='{profile-url}'>SAC-Portal</a> selbstständig anpassen.<br><br>" \
    "<h2>Sektion und Mitgliedschaft</h2><br><br>" \
    "Sektion: {section-name}<br>" \
    "Mitgliedschaftskategorie: {membership-category}<br>" \
    "Eintritt per: sofort<br><br>" \
    "{invoice-details}<br><br>" \
    "<h2>Personendaten</h2><br><br>" \
    "Kontaktperson<br>" \
    "Mitgliedernummer: {person-ids}<br>" \
    "Vorname: {first-name}<br>" \
    "Name: {last-name}<br>" \
    "Geburtsdatum: {birthday}<br>" \
    "E-Mail: {email}<br>" \
    "Telefonnumer: {phone-number}<br>" \
    "Adresszusatz: {address-care-of}<br>" \
    "Strasse und Nr: {street-with-number}<br>" \
    "Postfach: {postbox}<br>" \
    "PLZ: {zip-code}<br><br>" \
    "Ort: {town}<br><br>" \
    "Land: {country}<br><br>" \
    "Du wirst in kürze eine weitere E-Mail mit der Rechnung erhalten. Sobald die Zahlung bei uns eingegangen ist, " \
    "wird deine Mitgliedschaft vollständig aktiviert und alle Dienste können genutzt werden.<br><br>" \
    "Den digitalen Mitgliederausweis findest du in deinem <a href='{profile-url}'>SAC-Portal</a> Profil. " \
    "Weitere Details zum digitalen Mitgliederausweis findest im <a href='{faq-url}'>FAQ</a>.<br><br>" \
    "Viel Spass beim SAC!"},
  {custom_content_id: CustomContent.get(Signup::SektionMailer::APPROVAL_PENDING_CONFIRMATION).id,
   locale: "de",
   label: "SAC Eintritt: Bestellbestätigung mit Freigabe",
   subject: "SAC Eintritt Bestellbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Wir freuen uns sehr, dass du dich für eine SAC-Mitgliedschaft interessierst " \
    "und eine Mitgliedschaft beantragt hast.<br><br>" \
    "Dein Antrag wurde an die Sektion {section-name} weitergeleitet. " \
    "Über die Aufnahme neuer Mitglieder entscheidet die Sektion.<br><br>" \
    "Folgende Angaben haben wir von dir erhalten. Sollten diese nicht korrekt sein, kannst du " \
    "sie im <a href='{profile-url}'>SAC-Portal</a> selbstständig anpassen.<br><br>" \
    "<h2>Sektion und Mitgliedschaft</h2><br><br>" \
    "Sektion: {section-name}<br>" \
    "Mitgliedschaftskategorie: {membership-category}<br>" \
    "Eintritt per: sofort<br><br>" \
    "{invoice-details}<br><br>" \
    "<h2>Personendaten</h2><br><br>" \
    "Kontaktperson<br>" \
    "Mitgliedernummer: {person-ids}<br>" \
    "Vorname: {first-name}<br>" \
    "Name: {last-name}<br>" \
    "Geburtsdatum: {birthday}<br>" \
    "E-Mail: {email}<br>" \
    "Telefonnumer: {phone-number}<br>" \
    "Adresszusatz: {address-care-of}<br>" \
    "Strasse und Nr: {street-with-number}<br>" \
    "Postfach: {postbox}<br>" \
    "PLZ: {zip-code}<br><br>" \
    "Ort: {town}<br><br>" \
    "Land: {country}<br><br>" \
    "Du wirst in kürze eine weitere E-Mail mit der Rechnung erhalten. Sobald die Zahlung bei uns eingegangen ist, " \
    "wird deine Mitgliedschaft vollständig aktiviert und alle Dienste können genutzt werden.<br><br>" \
    "Den digitalen Mitgliederausweis findest du in deinem <a href='{profile-url}'>SAC-Portal</a> Profil. " \
    "Weitere Details zum digitalen Mitgliederausweis findest im <a href='{faq-url}'>FAQ</a>.<br><br>" \
    "Vielen Dank"},
  {custom_content_id: CustomContent.get(Memberships::JoinZusatzsektionMailer::CONFIRMATION).id,
   locale: "de",
   label: "Zusatzsektion Eintritt: Bestellbestätigung ohne Freigabe",
   subject: "Zusatzsektion Eintritt Bestellbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Wir freuen uns sehr, dass du dich für eine Zusatzsektion interessierst " \
    "und eine Mitgliedschaft beantragt hast.<br><br>" \
    "Folgende Angaben haben wir von dir erhalten. Sollten diese nicht korrekt sein, kannst du " \
    "sie im <a href='{profile-url}'>SAC-Portal</a> selbstständig anpassen.<br><br>" \
    "<h2>Sektion und Mitgliedschaft</h2><br><br>" \
    "Sektion: {section-name}<br>" \
    "Mitgliedschaftskategorie: {membership-category}<br>" \
    "Eintritt per: sofort<br><br>" \
    "{invoice-details}<br><br>" \
    "<h2>Personendaten</h2><br><br>" \
    "Kontaktperson<br>" \
    "Mitgliedernummer: {person-ids}<br>" \
    "Vorname: {first-name}<br>" \
    "Name: {last-name}<br>" \
    "Geburtsdatum: {birthday}<br>" \
    "E-Mail: {email}<br>" \
    "Telefonnumer: {phone-number}<br>" \
    "Adresszusatz: {address-care-of}<br>" \
    "Strasse und Nr: {street-with-number}<br>" \
    "Postfach: {postbox}<br>" \
    "PLZ: {zip-code}<br><br>" \
    "Ort: {town}<br><br>" \
    "Land: {country}<br><br>" \
    "Du wirst in kürze eine weitere E-Mail mit der Rechnung erhalten. Sobald die Zahlung bei uns eingegangen ist, " \
    "wird deine Mitgliedschaft vollständig aktiviert und alle Dienste können genutzt werden.<br><br>" \
    "Den digitalen Mitgliederausweis findest du in deinem <a href='{profile-url}'>SAC-Portal</a> Profil. " \
    "Weitere Details zum digitalen Mitgliederausweis findest im <a href='{faq-url}'>FAQ</a>.<br><br>" \
    "Vielen Dank!"},
  {custom_content_id: CustomContent.get(Memberships::JoinZusatzsektionMailer::APPROVAL_PENDING_CONFIRMATION).id,
   locale: "de",
   label: "Zusatzsektion Eintritt: Bestellbestätigung mit Freigabe",
   subject: "Zusatzsektion Eintritt Bestellbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Wir freuen uns sehr, dass du dich für eine Zusatzsektion interessierst " \
    "und eine Mitgliedschaft beantragt hast.<br><br>" \
    "Dein Antrag wurde an die Sektion {section-name} weitergeleitet. " \
    "Über die Aufnahme neuer Mitglieder entscheidet die Sektion.<br><br>" \
    "Folgende Angaben haben wir von dir erhalten. Sollten diese nicht korrekt sein, kannst du " \
    "sie im <a href='{profile-url}'>SAC-Portal</a> selbstständig anpassen.<br><br>" \
    "<h2>Sektion und Mitgliedschaft</h2><br><br>" \
    "Sektion: {section-name}<br>" \
    "Mitgliedschaftskategorie: {membership-category}<br>" \
    "Eintritt per: sofort<br><br>" \
    "{invoice-details}<br><br>" \
    "<h2>Personendaten</h2><br><br>" \
    "Kontaktperson<br>" \
    "Mitgliedernummer: {person-ids}<br>" \
    "Vorname: {first-name}<br>" \
    "Name: {last-name}<br>" \
    "Geburtsdatum: {birthday}<br>" \
    "E-Mail: {email}<br>" \
    "Telefonnumer: {phone-number}<br>" \
    "Adresszusatz: {address-care-of}<br>" \
    "Strasse und Nr: {street-with-number}<br>" \
    "Postfach: {postbox}<br>" \
    "PLZ: {zip-code}<br><br>" \
    "Ort: {town}<br><br>" \
    "Land: {country}<br><br>" \
    "Du wirst in kürze eine weitere E-Mail mit der Rechnung erhalten. Sobald die Zahlung bei uns eingegangen ist, " \
    "wird deine Zusatzmitgliedschaft vollständig aktiviert und alle Dienste können genutzt werden.<br><br>" \
    "Den digitalen Mitgliederausweis findest du in deinem <a href='{profile-url}'>SAC-Portal</a> Profil. " \
    "Weitere Details zum digitalen Mitgliederausweis findest im <a href='{faq-url}'>FAQ</a>.<br><br>" \
    "Vielen Dank!"},
  {custom_content_id: CustomContent.get(Invoices::SacMembershipsMailer::MEMBERSHIP_ACTIVATED).id,
   locale: "de",
   label: "SAC Eintritt: Mitgliedschaftsaktivierung",
   subject: "SAC Eintritt Bestellbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Vielen Dank für deine Zahlung, welche bei uns eingegangen ist. Deine Mitgliedschaft ist jetzt " \
    "vollständig aktiviert und alle Dienste des Schweizer Alpen-Clubs SAC können genutzt werden.<br><br>" \
    "Deinen digitalen Mitgliederausweis findest du in deinem Profil im <a href='{profile-url}'>SAC-Portal</a>. " \
    "Weitere Details zum digitalen Mitgliederausweis findest du in den FAQ.<br><br> " \
    "Viel Spass beim SAC!"},
  {custom_content_id: CustomContent.get(Memberships::TerminateMembershipMailer::LEAVE_ZUSATZSEKTION).id,
   locale: "de",
   label: "Mitgliedschaften: Bestätigung Austritt Zusatzsektion",
   subject: "Bestätigung Austritt Zusatzsektion",
   body: "Hallo {person-name},<br><br>" \
    "Der Austritt aus {sektion-name} wurde per {terminate-on} vorgenommen."},
  {custom_content_id: CustomContent.get(Memberships::TerminateMembershipMailer::TERMINATE_MEMBERSHIP).id,
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
    "Der Sektionswechsel zu {group-name} wurde vorgenommen."},
  {custom_content_id: CustomContent.get(People::NeuanmeldungenMailer::APPROVED).id,
   locale: "de",
   label: "SAC Eintritt: Antragsbestätigung",
   subject: "SAC Eintritt Antragsbestätigung",
   body: "Hallo {first-name},<br><br>" \
    "Vielen Dank für dein Interesse an einer Mitgliedschaft beim Schweizer Alpen-Club SAC.<br><br>" \
    "Die {sektion-name} hat deinen Antrag geprüft und wir freuen uns, dir mitzuteilen, dass dein Antrag angenommen " \
    "wurde. Herzlich Willkommen beim Schweizer Alpen-Club SAC!<br><br>" \
    "Du wirst in Kürze eine weitere E-Mail mit der Mitglieder-Rechnung erhalten. Sobald die Zahlung bei uns " \
    "eingegangen ist, wird deine Mitgliedschaft vollständig aktiviert und alle Dienste können genutzt werden.<br><br>" \
    "Den digitalen Mitgliederausweis findest du in deinem Profil im <a href='{profile-url}'>SAC-Portal</a>. " \
    "Weitere Details zum digitalen Mitgliederausweis findest du in den FAQ.<br><br>" \
    "Viel Spass beim SAC!"},
  {custom_content_id: CustomContent.get(People::NeuanmeldungenMailer::REJECTED).id,
   locale: "de",
   label: "SAC Eintritt: Antragsablehnung",
   subject: "SAC Eintritt Antragsablehnung",
   body: "Hallo {first-name},<br><br>" \
    "Vielen Dank für dein Interesse an einer Mitgliedschaft beim Schweizer Alpen-Club SAC.<br><br>" \
    "Die {sektion-name} hat deinen Antrag geprüft. Leider müssen wir dir mitteilen, " \
    "dass die Sektion deinem Antrag auf Mitgliedschaft nicht entsprechen kann.<br><br>" \
    "Jede Sektion hat ihre eigenen Aufnahmekriterien. " \
    "Somit empfehlen wir dir, deinen Antrag an eine andere Sektion deiner Wahl zu stellen.<br><br>" \
    "Vielen Dank für dein Verständnis.<br><br>" \
    "Bergsportliche Grüsse"})
