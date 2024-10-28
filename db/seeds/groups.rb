# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

def seed_magazin_abo(name, parent, title_de:, title_fr:, title_it:, title_en:)
  Group::AboMagazin.seed_once(:parent_id, :name) do |a|
    a.parent_id = parent.id
    a.name = name
    a.self_registration_role_type = Group::AboMagazin::Neuanmeldung.sti_name
    a.translations = [
      Group::Translation.new(locale: "de", custom_self_registration_title: title_de),
      Group::Translation.new(locale: "fr", custom_self_registration_title: title_fr),
      Group::Translation.new(locale: "it", custom_self_registration_title: title_it),
      Group::Translation.new(locale: "en", custom_self_registration_title: title_en)
    ]
  end
end

Group::SacCas.seed_once(:name, name: "SAC/CAS")

Group::Abos.seed_once(:parent_id, parent_id: Group.root.id)
abos = Group::Abos.find_by(parent_id: Group.root.id)

Group::AboMagazine.seed_once(:parent_id, parent_id: abos.id)
magazine = Group::AboMagazine.find_by(parent_id: abos.id)

seed_magazin_abo("Die Alpen DE", magazine,
  title_de: "Abo bestellen «Die Alpen»",
  title_fr: "S'abonner à la revue «Die Alpen»",
  title_it: "Abbonarsi a «Die Alpen»",
  title_en: "Subscribe to «Die Alpen»")
seed_magazin_abo("Les Alpes FR", magazine,
  title_de: "Abo bestellen «Les Alpes»",
  title_fr: "S'abonner à la revue «Les Alpes»",
  title_it: "Abbonarsi a «Les Alpes»",
  title_en: "Subscribe to  «Les Alpes»")
seed_magazin_abo("Le Alpi IT", magazine,
  title_de: "Abo bestellen «Le Alpi»",
  title_fr: "S'abonner à la revue «Le Alpi»",
  title_it: "Abbonarsi a «Le Alpi»",
  title_en: "Subscribe to  «Le Alpi»")

Group::AboTourenPortal.seed_once(:parent_id) do |a|
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboTourenPortal::Abonnent"
end

Group::AboBasicLogin.seed_once(:parent_id) do |a|
  a.parent_id = abos.id
  a.self_registration_role_type = "Group::AboBasicLogin::BasicLogin"
  a.translations = [
    Group::Translation.new(locale: "de", custom_self_registration_title: "Kostenloses SAC-Konto erstellen"),
    Group::Translation.new(locale: "fr", custom_self_registration_title: "Créer un compte CAS gratuit"),
    Group::Translation.new(locale: "it", custom_self_registration_title: "Creare un account CAS gratuito"),
    Group::Translation.new(locale: "en", custom_self_registration_title: "Create a free SAC account")
  ]
end
