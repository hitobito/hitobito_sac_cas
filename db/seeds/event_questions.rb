# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# recreate default event questions

Event::Question.seed_global({
  disclosure: :required,
  event_type: Event::Course.sti_name,
  translation_attributes: [
    {locale: :de, question: "Notfallkontakt 1 - Name und Telefonnummer"},
    {locale: :fr, question: "Contact d'urgence 1 - Nom et Numéro de téléphone"},
    {locale: :it, question: "Contatto di emergenza 1 - Nome e numero di telefono"}
  ]
})

Event::Question.seed_global({
  disclosure: :optional,
  event_type: Event::Course.sti_name,
  translation_attributes: [
    {locale: :de, question: "Notfallkontakt 2 - Name und Telefonnummer"},
    {locale: :fr, question: "Contact d'urgence 2 - Nom et Numéro de téléphone"},
    {locale: :it, question: "Contatto di emergenza 2 - Nome e numero di telefono"}
  ]
})
