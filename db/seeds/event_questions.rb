# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# recreate default event questions
data = [
  {
    de: 'Notfallkontakt 1 - Name und Telefonnummer',
    fr: "Contact d'urgence 1 - Nom et Numéro de téléphone",
    it: 'Contatto di emergenza 1 - Nome e numero di telefono'
  },
  {
    de: 'Notfallkontakt 2 - Name und Telefonnummer',
    fr: "Contact d'urgence 2 - Nom et Numéro de téléphone",
    it: 'Contatto di emergenza 2 - Nome e numero di telefono'
  }
]

unless Event::Question.where(question: data.pluck(:de)).count == 2
  Event::Question.where(event_id: nil).destroy_all

  data.each do |attrs|
    eq = Event::Question.create!( question: attrs.delete(:de))
    attrs.each do |key, question|
      I18n.with_locale(key) { eq.update!(question: question) }
    end
  end
end
